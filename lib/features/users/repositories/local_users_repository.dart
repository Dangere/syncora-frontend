import 'package:sqflite/sqflite.dart';
import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/core/data/enums/database_tables.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';

class LocalUsersRepository {
  final DatabaseManager _databaseManager;

  LocalUsersRepository(this._databaseManager);

  Future<void> upsertUser(User user) async {
    final db = await _databaseManager.getDatabase();

    await db.transaction((txn) async {
      await txn.insert(
        DatabaseTables.users,
        user.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> upsertUsers(List<User> users) async {
    final db = await _databaseManager.getDatabase();

    List<int> existingUserIds =
        (await db.rawQuery("SELECT id FROM ${DatabaseTables.users}"))
            .map((e) => e["id"] as int)
            .toList();

    await db.transaction((txn) async {
      final batch = txn.batch();

      for (User user in users) {
        if (!existingUserIds.contains(user.id)) {
          batch.insert(
            DatabaseTables.users,
            user.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          batch.update(
            DatabaseTables.users,
            user.toJson(),
            where: "id = ?",
            whereArgs: [user.id],
          );
        }
      }
      batch.commit(noResult: true);
    });
  }

  Future<User?> getUser(int id) async {
    final db = await _databaseManager.getDatabase();
    Map<String, dynamic> user =
        (await db.query(DatabaseTables.users, where: "id = ?", whereArgs: [id]))
            .single;

    if (user.isEmpty) return null;
    return User.fromJson(user);
  }

  Future<List<User>> getUsers(List<int> ids) async {
    final db = await _databaseManager.getDatabase();
    List<Map<String, dynamic>> users = await db.query(DatabaseTables.users,
        where: "id IN (${ids.map((id) => "?").join(",")})", whereArgs: ids);
    return users.isEmpty ? [] : users.map((e) => User.fromJson(e)).toList();
  }

  Future<List<User>> getGroupMembers(int groupId, bool includeOwner) async {
    final db = await _databaseManager.getDatabase();

    String includeOwnerQuery = includeOwner
        ? '''
    SELECT u.id, u.username, u.firstName, u.lastName, u.email, u.profilePictureURL, 0 AS sort_order FROM ${DatabaseTables.users} u
    INNER JOIN ${DatabaseTables.groups} g ON u.id = g.ownerUserId WHERE g.id = ?
    
    UNION
    '''
        : '';

    List<Map<String, dynamic>> users = await db.rawQuery('''

    $includeOwnerQuery

    SELECT u.id, u.username, u.firstName, u.lastName, u.email, u.profilePictureURL, 1 AS sort_order FROM ${DatabaseTables.users} u
    INNER JOIN ${DatabaseTables.groupsMembers} gm ON u.id = gm.userId WHERE gm.groupId = ?
    ORDER BY sort_order
    ''', [if (includeOwner) groupId, groupId]);
    return users.isEmpty ? [] : users.map((e) => User.fromJson(e)).toList();
  }

  // Removes users that dont belong to any group, except for the actual device user
  Future<void> purgeOrphanedUsers() async {
    final db = await _databaseManager.getDatabase();
    await db.rawQuery(
        "DELETE FROM ${DatabaseTables.users} WHERE isMainUser = 0 AND id NOT IN (SELECT userId FROM ${DatabaseTables.groupsMembers}) AND id NOT IN (SELECT ownerUserId FROM ${DatabaseTables.groups});");
  }

  Future<String?> userProfileUrl(int userId) async {
    final db = await _databaseManager.getDatabase();

    Map<String, Object?>? query = (await db.rawQuery(
            "SELECT profilePictureURL FROM ${DatabaseTables.users} WHERE id = $userId"))
        .firstOrNull;
    String? url = query?["profilePictureURL"] as String?;

    if (url != null && url.isNotEmpty) {
      return url;
    }
    return null;
  }
}

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

  Future<User> getUser(int id) async {
    final db = await _databaseManager.getDatabase();
    Map<String, dynamic> user =
        (await db.query(DatabaseTables.users, where: "id = ?", whereArgs: [id]))
            .single;

    if (user.isEmpty) throw Exception("User with id $id not found");
    return User.fromJson(user);
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
    return url;
  }
}

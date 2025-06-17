import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';

class LocalGroupsRepository {
  final DatabaseManager _databaseManager;

  LocalGroupsRepository(this._databaseManager);

  Future<Group> createGroup(String title, String description) {
    // TODO: implement createGroup
    throw UnimplementedError();
  }

  Future<List<Group>> getAllGroups() async {
    final db = await _databaseManager.getDatabase();

    List<Map<String, Object?>> groups = await db.rawQuery('''
     SELECT groups.id, groups.title,
           groupsMembers.userId
    FROM groups
    INNER JOIN groupsMembers
    ON groups.id = groupsMembers.groupId
     ''');

    for (var i = 0; i < groups.length; i++) {
      Logger().d(groups[i]);
    }

    throw UnimplementedError("Unfinished method");
  }

  Future<void> leaveGroup(int groupId) {
    // TODO: implement leaveGroup
    throw UnimplementedError();
  }

  // Future<void> createTempGroup(Group group) async {
  //   await _localDataSource.saveGroup(group);
  // }

  Future<void> upsertGroup(Map<String, dynamic> group) async {
    // Get a reference to the database.
    final db = await _databaseManager.getDatabase();

    // Insert the group into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same group is inserted twice.
    //
    // In this case, replace any previous data.

    await db.transaction((txn) async {
      await txn.insert(
        "groups",
        group,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (var i = 0; i < group["members"].length; i++) {
        await txn.insert(
          "groupsMembers",
          {
            "groupId": group["id"],
            "userId": group["members"][i],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> upsertAllGroups(List<Group> groups) async {
    final db = await _databaseManager.getDatabase();

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (Group group in groups) {
        batch.insert(
          "groups",
          group.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        for (var i = 0; i < group.members.length; i++) {
          batch.insert(
            "groupsMembers",
            {
              "groupId": group.id,
              "userId": group.members[i],
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      batch.commit(noResult: true);
    });
  }
}

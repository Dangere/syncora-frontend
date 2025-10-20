import 'package:sqflite/sqflite.dart';
import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/core/data/enums/database_tables.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/models/group_dto.dart';

class LocalGroupsRepository {
  final DatabaseManager _databaseManager;

  LocalGroupsRepository(this._databaseManager);

  Future<void> createGroup(Group newGroup) async {
    final db = await _databaseManager.getDatabase();

    await db.insert(DatabaseTables.groups, newGroup.toTable());
  }

  Future<bool> groupExist(int groupId) async {
    final db = await _databaseManager.getDatabase();

    List<Map<String, dynamic>> groupQuery = await db.rawQuery(
        ''' SELECT * FROM ${DatabaseTables.groups} WHERE id = $groupId''');
    return groupQuery.isNotEmpty;
  }

  Future<List<Group>> getAllGroups() async {
    final db = await _databaseManager.getDatabase();

    List<Map<String, dynamic>> groups = await db.rawQuery(
        ''' SELECT * FROM ${DatabaseTables.groups} ORDER BY date(creationDate) ASC''');

    List<Map<String, dynamic>> members =
        await db.rawQuery(''' SELECT * FROM ${DatabaseTables.groupsMembers}
        LEFT JOIN ${DatabaseTables.users} ON ${DatabaseTables.groupsMembers}.userId = ${DatabaseTables.users}.id''');

    List<Map<String, dynamic>> tasks =
        await db.rawQuery(''' SELECT * FROM ${DatabaseTables.tasks}
        LEFT JOIN ${DatabaseTables.groups} ON ${DatabaseTables.tasks}.groupId = ${DatabaseTables.groups}.id''');

    List<Group> groupList = List.empty(growable: true);

    for (var i = 0; i < groups.length; i++) {
      List<int> membersIdsForGroup = members
          .where((member) => member["groupId"] == groups[i]["id"])
          .map((e) => e["id"] as int)
          .toList();

      List<int> tasksIdsForGroup = tasks
          .where((task) => task["groupId"] == groups[i]["id"])
          .map((e) => e["id"] as int)
          .toList();

      Group group = Group.fromJsonWithIds(
          json: groups[i],
          taskIds: tasksIdsForGroup,
          groupMembersIds: membersIdsForGroup);
      groupList.add(group);
    }

    groupList.sort((a, b) => a.creationDate.compareTo(b.creationDate));

    return groupList;
  }

  Future<Group> getGroup(int groupId) async {
    final db = await _databaseManager.getDatabase();

    List<Map<String, dynamic>> groupQuery = await db.rawQuery(
        ''' SELECT * FROM ${DatabaseTables.groups} WHERE id = $groupId''');

    if (groupQuery.isEmpty) {
      throw Exception("Group with id $groupId not found");
    }

    List<Map<String, dynamic>> members =
        await db.rawQuery(''' SELECT * FROM ${DatabaseTables.groupsMembers}
        LEFT JOIN ${DatabaseTables.users} ON ${DatabaseTables.groupsMembers}.userId = ${DatabaseTables.users}.id WHERE ${DatabaseTables.groupsMembers}.groupId = $groupId''');

    List<Map<String, dynamic>> tasks =
        await db.rawQuery(''' SELECT * FROM ${DatabaseTables.tasks}
        LEFT JOIN ${DatabaseTables.groups} ON ${DatabaseTables.tasks}.groupId = ${DatabaseTables.groups}.id WHERE ${DatabaseTables.tasks}.groupId = $groupId''');

    List<int> membersIdsForGroup = members
        .where((member) => member["groupId"] == groupQuery[0]["id"])
        .map((e) => e["id"] as int)
        .toList();

    List<int> tasksIdsForGroup = tasks
        .where((task) => task["groupId"] == groupQuery[0]["id"])
        .map((e) => e["id"] as int)
        .toList();

    // tasksIdsForGroup.forEach((element) {
    //
    // });

    Group group = Group.fromJsonWithIds(
        json: groupQuery[0],
        taskIds: tasksIdsForGroup,
        groupMembersIds: membersIdsForGroup);

    return group;
  }

  Future<void> leaveGroup(int groupId) {
    // TODO: implement leaveGroup
    throw UnimplementedError();
  }

  Future<int> updateGroupDetails(
      String? title, String? description, int groupId) async {
    final db = await _databaseManager.getDatabase();

    if (title == null && description == null) return 0;

    Map<String, Object?> values = {};
    if (title != null) {
      values["title"] = title;
    }

    if (description != null) {
      values["description"] = description;
    }

    return await db.update(
      DatabaseTables.groups,
      values,
      where: "id = ?",
      whereArgs: [groupId],
    );
  }

  Future<void> upsertGroups(List<GroupDTO> groups) async {
    // throw UnimplementedError("No upsert method");

    final db = await _databaseManager.getDatabase();

    List<int> existingGroupsIds =
        (await db.rawQuery("SELECT id FROM ${DatabaseTables.groups}"))
            .map((e) => e["id"] as int)
            .toList();

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (GroupDTO group in groups) {
        // Check if the group already exists by its ID

        if (!existingGroupsIds.contains(group.id)) {
          batch.insert(
            DatabaseTables.groups,
            group.toTable(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          batch.update(
            DatabaseTables.groups,
            group.toTable(),
            where: "id = ?",
            whereArgs: [group.id],
          );
        }

        batch.delete(DatabaseTables.groupsMembers,
            where: "groupId = ?", whereArgs: [group.id]);
        for (final memberId in group.groupMembers) {
          batch.insert(
            DatabaseTables.groupsMembers,
            {
              "groupId": group.id,
              "userId": memberId,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      batch.commit(noResult: true);
    });
  }

  // Method used to mark group as deleted
  Future<int> markGroupAsDeleted(int groupId) async {
    final db = await _databaseManager.getDatabase();

    return await db.update(DatabaseTables.groups, {"isDeleted": 1},
        where: "id = ?", whereArgs: [groupId]);
  }

  // Method used to unmark group as deleted
  Future<int> unmarkGroupAsDeleted(int groupId) async {
    final db = await _databaseManager.getDatabase();

    return await db.update(DatabaseTables.groups, {"isDeleted": 0},
        where: "id = ?", whereArgs: [groupId]);
  }

  // Method used to wipe groups marked as deleted
  Future<int> wipeDeletedGroup(int groupId) async {
    final db = await _databaseManager.getDatabase();

    return await db.delete(DatabaseTables.groups,
        where: "isDeleted = ? AND id != ?", whereArgs: [1, groupId]);
  }

  // Method used to update temp ids of groups to ones issued by the backend
  Future<int> updateGroupId(int tempId, int newId) async {
    final db = await _databaseManager.getDatabase();

    return await db.update(
      DatabaseTables.groups,
      {"id": newId, "clientGeneratedId": tempId},
      where: "id = ?",
      whereArgs: [tempId],
    );
  }
}

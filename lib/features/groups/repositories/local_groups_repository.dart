import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/core/data/enums/database_tables.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/models/group_dto.dart';

class LocalGroupsRepository {
  final DatabaseManager _databaseManager;

  LocalGroupsRepository(this._databaseManager);

  // Future<void> seedTempGroupMembers(int groupId) async {
  //   final db = await _databaseManager.getDatabase();
  //   final now = DateTime.now().toUtc();

  //   int firstUserId = -now.millisecondsSinceEpoch;
  //   int secondUserId = -now.millisecondsSinceEpoch + 1;

  //   User user = User(
  //       id: firstUserId,
  //       username: "user" + firstUserId.toString().substring(5, 10),
  //       email: firstUserId.toString());
  //   User user2 = User(
  //       id: secondUserId,
  //       username: "user" + secondUserId.toString().substring(4, 10),
  //       email: secondUserId.toString());

  //   await db.transaction((txn) async {
  //     final batch = txn.batch();
  //     batch.insert("users", user.toJson());
  //     batch.insert("users", user2.toJson());
  //     // make sure groupsMembers cant have deduplicated entries or at least use distinct when querying
  //     batch
  //         .insert("groupsMembers", {"groupId": groupId, "userId": firstUserId});
  //     batch.insert(
  //         "groupsMembers", {"groupId": groupId, "userId": secondUserId});

  //     await batch.commit(noResult: true);
  //   });
  // }

  Future<Group> createGroup(
      String title, String description, int ownerId) async {
    final now = DateTime.now().toUtc();

    Group newGroup = Group(
        id: -now.millisecondsSinceEpoch,
        groupMembersIds: const [],
        tasksIds: const [],
        ownerUserId: ownerId,
        creationDate: now,
        title: title,
        description: description);

    final db = await _databaseManager.getDatabase();

    await db.insert(DatabaseTables.groups, newGroup.toTable());

    // await seedTempGroupMembers(newGroup.id);

    // Logger().w(await db.rawQuery('SELECT * FROM groups'));

    return newGroup;
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
    //   Logger().w(element);
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

  Future<void> updateGroupDetails(
      String? title, String? description, int groupId) async {
    final db = await _databaseManager.getDatabase();
    await db.update(
      DatabaseTables.groups,
      {"title": title, "description": description},
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

    Logger().w(existingGroupsIds);

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

  Future<void> deleteGroup(int groupId) async {
    final db = await _databaseManager.getDatabase();
    await db
        .delete(DatabaseTables.groups, where: "id = ?", whereArgs: [groupId]);
  }
}

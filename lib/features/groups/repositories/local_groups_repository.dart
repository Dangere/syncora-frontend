import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/core/data/enums/database_tables.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';

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
        groupMembers: [],
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

    // List<Map<String, dynamic>> groups = await db.rawQuery(
    //     ''' SELECT groups.id as groupId, groups.title, groups.description, groups.creationDate, groups.ownerUserId, users.id AS userId
    //  FROM groups
    //  LEFT JOIN groupsMembers ON groups.id = groupsMembers.groupId
    //  LEFT JOIN users ON groupsMembers.userId = users.id''');

    List<Map<String, dynamic>> groups = await db.rawQuery(
        ''' SELECT * FROM ${DatabaseTables.groups} ORDER BY date(creationDate) ASC''');

    List<Map<String, dynamic>> members =
        await db.rawQuery(''' SELECT * FROM ${DatabaseTables.groupsMembers}
        LEFT JOIN ${DatabaseTables.users} ON ${DatabaseTables.groupsMembers}.userId = users.id''');

    List<Group> groupList = List.empty(growable: true);

    for (var i = 0; i < groups.length; i++) {
      Group group = Group.fromJsonWithMembers(
          groups[i],
          members
              .where((member) => member["groupId"] == groups[i]["id"])
              .toList());
      groupList.add(group);
    }

    groupList.sort((a, b) => a.creationDate.compareTo(b.creationDate));

    // Logger().w(groupList.map((e) => e.toJson()).toList());
    // Logger().w(members);

    // Logger().w(await db.rawQuery(''' SELECT * FROM ${DatabaseTables.users}'''));

    // throw UnimplementedError("Unfinished getAllGroups method");
    return groupList;
  }

  Future<void> leaveGroup(int groupId) {
    // TODO: implement leaveGroup
    throw UnimplementedError();
  }

  Future<void> upsertGroups(List<Group> groups) async {
    // throw UnimplementedError("No upsert method");

    final db = await _databaseManager.getDatabase();

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (Group group in groups) {
        batch.insert(
          DatabaseTables.groups,
          group.toTable(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        for (var i = 0; i < group.groupMembers.length; i++) {
          batch.insert(
            DatabaseTables.groupsMembers,
            {
              "groupId": group.id,
              "userId": group.groupMembers[i],
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      batch.commit(noResult: true);
    });
  }
}

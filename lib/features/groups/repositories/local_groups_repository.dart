import 'package:sqflite/sqflite.dart';
import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/core/data/enums/database_tables.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/models/group_dto.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';

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

  Future<List<Group>> getAllGroups(
      GroupsFilter filter, bool ascending, int userId) async {
    final db = await _databaseManager.getDatabase();

    final String order =
        ascending ? "ORDER BY creationDate ASC" : "ORDER BY creationDate DESC";

    final String groupsQuery = switch (filter) {
      GroupsFilter.owned => '''SELECT
        id, clientGeneratedId, ownerUserId, title, description, creationDate, 
        (SELECT json_group_array(userId) FROM ${DatabaseTables.groupsMembers} WHERE groupId = g.id)
        AS members, 
        (SELECT json_group_array(id) FROM ${DatabaseTables.tasks} WHERE groupId = g.id AND isDeleted = 0)
        as tasks
        FROM ${DatabaseTables.groups} g
        WHERE isDeleted = 0 AND ownerUserId = $userId
         $order''',
      GroupsFilter.shared => '''SELECT
        id, clientGeneratedId, ownerUserId, title, description, creationDate, 
        (SELECT json_group_array(userId) FROM ${DatabaseTables.groupsMembers} WHERE groupId = g.id)
        AS members, 
        (SELECT json_group_array(id) FROM ${DatabaseTables.tasks} WHERE groupId = g.id AND isDeleted = 0)
        as tasks
        FROM ${DatabaseTables.groups} g
        WHERE isDeleted = 0 AND ownerUserId != $userId
         $order''',
      GroupsFilter.inProgress => '''SELECT
        id, clientGeneratedId, ownerUserId, title, description, creationDate,
        (SELECT json_group_array(userId) FROM ${DatabaseTables.groupsMembers} WHERE groupId = g.id)
        AS members, 
        (SELECT json_group_array(id) FROM ${DatabaseTables.tasks} WHERE groupId = g.id AND isDeleted = 0)
        as tasks,
        (EXISTS (
        SELECT 1
          FROM ${DatabaseTables.tasks}
          WHERE groupId = g.id AND isDeleted = 0)
        AND NOT EXISTS (
          SELECT 1
          FROM ${DatabaseTables.tasks}
          WHERE groupId = g.id AND isDeleted = 0 AND completedById IS NULL
        )) AS completed
        FROM ${DatabaseTables.groups} g
        WHERE isDeleted = 0 AND completed = 0''',
      GroupsFilter.completed => '''SELECT
        id, clientGeneratedId, ownerUserId, title, description, creationDate,
        (SELECT json_group_array(userId) FROM ${DatabaseTables.groupsMembers} WHERE groupId = g.id)
        AS members, 
        (SELECT json_group_array(id) FROM ${DatabaseTables.tasks} WHERE groupId = g.id AND isDeleted = 0)
        as tasks, 
        (EXISTS (
        SELECT 1
          FROM ${DatabaseTables.tasks}
          WHERE groupId = g.id AND isDeleted = 0)
        AND NOT EXISTS (
          SELECT 1
          FROM ${DatabaseTables.tasks}
          WHERE groupId = g.id AND isDeleted = 0 AND completedById IS NULL
        )) AS completed
        FROM ${DatabaseTables.groups} g
        WHERE isDeleted = 0 AND completed = 1'''
    };

    List<Map<String, dynamic>> groups = await db.rawQuery(groupsQuery);

    List<Group> groupList =
        groups.map((group) => Group.fromJson(group)).toList();

    return groupList;
  }

  Future<Group> getGroup(int groupId) async {
    final db = await _databaseManager.getDatabase();

    List<Map<String, dynamic>> groupRow = await db.rawQuery('''SELECT
        id, clientGeneratedId, ownerUserId, title, description, creationDate, 
        (SELECT json_group_array(userId) FROM ${DatabaseTables.groupsMembers} WHERE groupId = g.id)
        AS members, 
        (SELECT json_group_array(id) FROM ${DatabaseTables.tasks} WHERE groupId = g.id AND isDeleted = 0)
        as tasks
        FROM ${DatabaseTables.groups} g
        WHERE isDeleted = 0 AND id = $groupId''');

    if (groupRow.isEmpty) {
      throw Exception("Group with id $groupId not found");
    }

    Group group = Group.fromJson(groupRow[0]);

    return group;
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
        where: "isDeleted = ? AND id = ?", whereArgs: [1, groupId]);
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

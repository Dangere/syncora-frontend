import 'package:sqflite/sqflite.dart';
import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/core/data/enums/database_tables.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_payload.dart';

class OutboxRepository {
  final DatabaseManager _databaseManager;

  OutboxRepository({required databaseManager})
      : _databaseManager = databaseManager;

  Future<int> insertEntry(OutboxEntry entry) async {
    Database db = await _databaseManager.getDatabase();

    // Handing when we trying to insert a delete a group entry, we mark the entries that either correspond to the group or reference it as ignored
    // And not insert the delete entry if we ignored its creation entry
    if (entry.actionType == OutboxActionType.delete &&
        entry.entityType == OutboxEntityType.group) {
      bool groupCreationStillPending = await db.query(DatabaseTables.outbox,
          where:
              "entityId = ? AND actionType = ? AND status = ? And entityType = ?",
          whereArgs: [
            entry.entityId,
            OutboxActionType.create.index,
            OutboxStatus.pending.index,
            OutboxEntityType.group.index
          ]).then((value) => value.isNotEmpty);

      await db.update(
          DatabaseTables.outbox, {"status": OutboxStatus.ignored.index},
          where: "entityId = ? or dependencyId = ? AND status = ?",
          whereArgs: [
            entry.entityId,
            entry.entityId,
            OutboxStatus.pending.index
          ]);

      // we dont continue to inserting the delete entry because we already ignored its creation
      if (groupCreationStillPending) {
        return 1;
      }
    }

    // Handing when we trying to insert a delete a task entry, we mark any entries that correspond to it as ignored
    // And not insert the delete entry
    if (entry.actionType == OutboxActionType.delete &&
        entry.entityType == OutboxEntityType.task) {
      bool taskCreationStillPending = await db.query(DatabaseTables.outbox,
          where:
              "entityId = ? AND actionType = ? AND status = ? And entityType = ?",
          whereArgs: [
            entry.entityId,
            OutboxActionType.create,
            OutboxStatus.pending.index,
            OutboxEntityType.task
          ]).then((value) => value.isNotEmpty);

      await db.update(
          DatabaseTables.outbox, {"status": OutboxStatus.ignored.index},
          where: "entityId = ? AND status = ?",
          whereArgs: [entry.entityId, OutboxStatus.pending.index]);

      // we dont continue to inserting the delete entry because we already ignored its creation
      if (taskCreationStillPending) {
        return 1;
      }
    }

    // Handing when we trying to insert an update a group entry, we make sure to remove previous update entries as now that last one hold the latest data
    if (entry.actionType == OutboxActionType.update &&
        entry.entityType == OutboxEntityType.group) {
      UpdateGroupPayload currentPayload = entry.payload!.asUpdateGroupPayload!;
      List<OutboxEntry> pendingUpdateEntriesForGroup = await db.query(
          DatabaseTables.outbox,
          where:
              "entityId = ? AND actionType = ? AND status = ? And entityType = ?",
          whereArgs: [
            entry.entityId,
            OutboxActionType.update.index,
            OutboxStatus.pending.index,
            OutboxEntityType.group.index
          ]).then(
          (value) => value.map((e) => OutboxEntry.fromTable(e)).toList());

      for (var i = 0; i < pendingUpdateEntriesForGroup.length; i++) {
        UpdateGroupPayload payload =
            pendingUpdateEntriesForGroup[i].payload!.asUpdateGroupPayload!;

        // Since we cant update both the title and description at the same time, we will only have two update entries per group

        // if we got a entry trying to update the title, but we are also trying to update the title as well, we ignore that entry
        if (payload.title != null && currentPayload.title != null) {
          markEntryIgnored(pendingUpdateEntriesForGroup[i].id!);
        }

        // if we got a entry trying to update the description, but we are also trying to update the description as well, we ignore that entry
        if (payload.description != null && currentPayload.description != null) {
          markEntryIgnored(pendingUpdateEntriesForGroup[i].id!);
        }
      }
    }

    // Handing when we trying to insert an update a task entry, we make sure to remove previous update entries as now that last one hold the latest data
    if (entry.actionType == OutboxActionType.update &&
        entry.entityType == OutboxEntityType.task) {
      UpdateTaskPayload currentPayload = entry.payload!.asUpdateTaskPayload!;
      List<OutboxEntry> pendingUpdateEntriesForTask = await db.query(
          DatabaseTables.outbox,
          where:
              "entityId = ? AND actionType = ? AND status = ? And entityType = ?",
          whereArgs: [
            entry.entityId,
            OutboxActionType.update.index,
            OutboxStatus.pending.index,
            OutboxEntityType.task.index
          ]).then(
          (value) => value.map((e) => OutboxEntry.fromTable(e)).toList());

      for (var i = 0; i < pendingUpdateEntriesForTask.length; i++) {
        UpdateTaskPayload payload =
            pendingUpdateEntriesForTask[i].payload!.asUpdateTaskPayload!;

        // Since we cant update both the title and description at the same time, we will only have two update entries per task

        // if we got a entry trying to update the title, but we are also trying to update the title as well, we ignore that entry
        if (payload.title != null && currentPayload.title != null) {
          markEntryIgnored(pendingUpdateEntriesForTask[i].id!);
        }

        // if we got a entry trying to update the description, but we are also trying to update the description as well, we ignore that entry
        if (payload.description != null && currentPayload.description != null) {
          markEntryIgnored(pendingUpdateEntriesForTask[i].id!);
        }
      }
    }

    // Handing when we trying to insert a mark a task entry, we make sure to remove previous mark entries as now that last one hold the latest data
    if (entry.actionType == OutboxActionType.mark &&
        entry.entityType == OutboxEntityType.task) {
      await db.update(
          DatabaseTables.outbox, {"status": OutboxStatus.ignored.index},
          where: "entityId = ? AND actionType = ? AND status = ?",
          whereArgs: [
            entry.entityId,
            OutboxActionType.mark.index,
            OutboxStatus.pending.index
          ]);
    }

    // When inserting entires that depend on an old return point such as update entires requiring "old" data in its payload to fall back to in case of failing
    // we should update that return point if theres another entry that already edited the original return point which made the new entry reference modified data in its payload

    // For example, if the user edits the group title twice, the first entry will reference the original group title as its "oldTitle"
    // But the second entry will reference the first entry's title as its "oldTitle".
    // So ultimately, if the entires fails, it will try falling back to the "oldTitle" but that data is actually modified by the first entry

    // We just check if theres an entry in process with an action type other than "create" and take its old data as the "old" data for this entry
    OutboxEntry? inProgressEntry = await _getInProgressEntry(
        entry.entityId, entry.actionType, entry.entityType);

    if (inProgressEntry != null) {
      if (entry.actionType == OutboxActionType.update &&
          entry.entityType == OutboxEntityType.group) {}

      // entry.payload!.asUpdateGroupPayload.oldTitle =
      //     inProgressEntry.payload!.asUpdateGroupPayload.title;
      // entry.payload!.asUpdateGroupPayload.oldDescription =
      //     inProgressEntry.payload!.asUpdateGroupPayload.description;
    }

    return await db.insert(DatabaseTables.outbox, entry.toTable());
  }

  // We use this to know if an entry of the same type is in progress
  Future<OutboxEntry?> _getInProgressEntry(
      int entityId, OutboxActionType action, OutboxEntityType type) async {
    Database db = await _databaseManager.getDatabase();

    var query = await db.query(DatabaseTables.outbox,
        where: "id = ? AND status = ? AND actionType = ? AND entityType = ?",
        whereArgs: [
          entityId,
          OutboxStatus.inProcess.index,
          action.index,
          type.index
        ]);

    if (query.isEmpty) return null;

    return OutboxEntry.fromTable(query.first);
  }

  Future<void> deleteEntry(int entryId) async {
    Database db = await _databaseManager.getDatabase();

    await db
        .delete(DatabaseTables.outbox, where: "id = ?", whereArgs: [entryId]);
  }

  Future<List<OutboxEntry>> getPendingEntries() async {
    Database db = await _databaseManager.getDatabase();

    List<Map<String, Object?>> query = await db.query(DatabaseTables.outbox,
        where: "status = ?",
        whereArgs: [OutboxStatus.pending.index],
        orderBy: "creationDate DESC");
    List<OutboxEntry> entries =
        query.map((e) => OutboxEntry.fromTable(e)).toList();

    return entries;
  }

  Future<void> completeEntry(int id) async {
    Database db = await _databaseManager.getDatabase();

    await db.update(
        DatabaseTables.outbox, {"status": OutboxStatus.complete.index},
        where: "id = ?", whereArgs: [id]);
  }

  Future<void> failEntry(int id) async {
    Database db = await _databaseManager.getDatabase();

    await db.update(
        DatabaseTables.outbox, {"status": OutboxStatus.failed.index},
        where: "id = ?", whereArgs: [id]);
  }

  Future<void> markEntryInProcess(int id) async {
    Database db = await _databaseManager.getDatabase();

    await db.update(
        DatabaseTables.outbox, {"status": OutboxStatus.inProcess.index},
        where: "id = ?", whereArgs: [id]);
  }

  Future<void> markEntryPending(int id) async {
    Database db = await _databaseManager.getDatabase();

    await db.update(
        DatabaseTables.outbox, {"status": OutboxStatus.pending.index},
        where: "id = ?", whereArgs: [id]);
  }

  Future<void> markEntryIgnored(int id) async {
    Database db = await _databaseManager.getDatabase();

    await db.update(
        DatabaseTables.outbox, {"status": OutboxStatus.ignored.index},
        where: "id = ?", whereArgs: [id]);
  }

  // Returns the server id of a row in tasks or group tables using temp ids
  Future<int> getServerId(int tempId) async {
    Database db = await _databaseManager.getDatabase();

    var result = await db.query(DatabaseTables.groups,
        where: "clientGeneratedId = ?", whereArgs: [tempId]);
    if (result.isEmpty) {
      result = await db.query(DatabaseTables.tasks,
          where: "clientGeneratedId = ?", whereArgs: [tempId]);
    }

    if (result.isEmpty) {
      throw Exception("Group or task with temp id $tempId was not found");
    }

    return result.first["id"] as int;
  }
}

import 'package:logger/logger.dart';
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

    // TODO: One bug i noticed is when queuing a bunch of task deletion then group deletion (the logic below will mark the tasks deletions as ignored) leaves us with a group deletion entry only, which is fine but if that task deletion fails for whatever reason and reverted to user, the task deletions wont be reverted because they were makred as ignored

    // TODO: Another related bug, if a queue has a mark task entry and a delete task entry, only the delete will be processed and reverted in failure, but it will be marked (the mark action failed too but didnt revert because the entry for it was ignored all together)

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

      await ignoreDependingEntries(entry.entityId);

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
            OutboxActionType.create.index,
            OutboxStatus.pending.index,
            OutboxEntityType.task.index
          ]).then((value) => value.isNotEmpty);

      await ignoreDependingEntries(entry.entityId);

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

    Logger().w("Found in progress entry: $inProgressEntry");
    if (inProgressEntry != null) {
      // If its an update group entry we need to update its old data to be the data from the in progress entry
      if (entry.actionType == OutboxActionType.update &&
          entry.entityType == OutboxEntityType.group) {
        // Getting the in progress payload that contain the proper return point data
        UpdateGroupPayload inProgressPayload =
            inProgressEntry.payload!.asUpdateGroupPayload!;

        // Setting the return point data to the in progress entry
        entry.payload!.asUpdateGroupPayload!.refreshOldData(inProgressPayload);
      }

      // If its an update task entry we need to update its old data to be the data from the in progress entry
      if (entry.actionType == OutboxActionType.update &&
          entry.entityType == OutboxEntityType.task) {
        // Getting the in progress payload that contain the proper return point data
        UpdateTaskPayload inProgressPayload =
            inProgressEntry.payload!.asUpdateTaskPayload!;

        // Setting the return point data to the in progress entry
        entry.payload!.asUpdateTaskPayload!.refreshOldData(inProgressPayload);
      }
    }

    return await db.insert(DatabaseTables.outbox, entry.toTable());
  }

  // We use this to know if an entry of the same type is in progress
  Future<OutboxEntry?> _getInProgressEntry(
      int entityId, OutboxActionType action, OutboxEntityType type) async {
    Database db = await _databaseManager.getDatabase();

    var query = await db.query(DatabaseTables.outbox,
        where:
            "entityId = ? AND status = ? AND actionType = ? AND entityType = ?",
        whereArgs: [
          entityId,
          OutboxStatus.inProcess.index,
          action.index,
          type.index
        ]);

    if (query.isEmpty) return null;

    return OutboxEntry.fromTable(query.first);
  }

  Future<void> ignoreDependingEntries(int entityId) async {
    Database db = await _databaseManager.getDatabase();

    await db.update(
        DatabaseTables.outbox, {"status": OutboxStatus.ignored.index},
        where: "(entityId = ? or dependencyId = ?) AND status = ?",
        whereArgs: [entityId, entityId, OutboxStatus.pending.index]);
  }

  Future<void> unignoreDependingEntries(int entityId) async {
    Database db = await _databaseManager.getDatabase();

    await db.update(
        DatabaseTables.outbox, {"status": OutboxStatus.pending.index},
        where: "(entityId = ? or dependencyId = ?) AND status = ?",
        whereArgs: [entityId, entityId, OutboxStatus.ignored.index]);
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
        orderBy: "creationDate ASC");
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

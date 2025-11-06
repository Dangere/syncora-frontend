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

    // When inserting entires that depend on an old return point such as update entires requiring "old" data in its payload to fall back to in case of failing
    // we should update that return point if theres another entry that already edited the original return point which made the new entry reference modified data in its payload

    // For example, if the user edits the group title twice, the first entry will reference the original group title as its "oldTitle"
    // But the second entry will reference the first entry's title as its "oldTitle".
    // So ultimately, if the entires fails, it will try falling back to the "oldTitle" but that data is actually modified by the first entry

    // We just check if theres an entry in process with an action type other than "create" and take its old data as the "old" data for this entry
    OutboxEntry? inProgressEntry =
        await _getInProgressEntry(entry.actionType, entry.entityType);

    if (inProgressEntry != null) {
      // entry.payload!.asUpdateGroupPayload.oldTitle =
      //     inProgressEntry.payload!.asUpdateGroupPayload.title;
      // entry.payload!.asUpdateGroupPayload.oldDescription =
      //     inProgressEntry.payload!.asUpdateGroupPayload.description;
    }

    return await db.insert(DatabaseTables.outbox, entry.toTable());
  }

  // We use this to know if an entry of the same type is in progress
  Future<OutboxEntry?> _getInProgressEntry(
      OutboxActionType action, OutboxEntityType type) async {
    Database db = await _databaseManager.getDatabase();

    var query = await db.query(DatabaseTables.outbox,
        where: "status = ? AND actionType = ? AND entityType = ?",
        whereArgs: [OutboxStatus.inProcess.index, action.index, type.index]);

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

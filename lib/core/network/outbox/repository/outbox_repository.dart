import 'package:sqflite/sqflite.dart';
import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/core/data/enums/database_tables.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';

class OutboxRepository {
  final DatabaseManager _databaseManager;

  OutboxRepository({required databaseManager})
      : _databaseManager = databaseManager;

  Future<void> insertEntry(OutboxEntry entry) async {
    Database db = await _databaseManager.getDatabase();

    await db.insert(DatabaseTables.outbox, entry.toTable());
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
}

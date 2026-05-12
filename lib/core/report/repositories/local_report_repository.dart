import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/core/data/database_tables.dart';
import 'package:syncora_frontend/core/report/report.dart';

class LocalReportRepository {
  final DatabaseManager _databaseManager;

  LocalReportRepository(this._databaseManager);

  Future<void> insertReport(Report report) async {
    final db = await _databaseManager.getDatabase();

    await db.insert(DatabaseTables.reports, report.toTable());
  }

  Future<Report> getReport(int id) async {
    final db = await _databaseManager.getDatabase();

    List<Map<String, Object?>> rows = await db
        .query(DatabaseTables.reports, where: "id = ?", whereArgs: [id]);

    return Report.fromTable(rows.first);
  }

  Future<void> updateReportToSent(int reportId) async {
    final db = await _databaseManager.getDatabase();

    await db.update(DatabaseTables.reports, {"isSent": 1},
        where: "id = ?", whereArgs: [reportId]);
  }
}

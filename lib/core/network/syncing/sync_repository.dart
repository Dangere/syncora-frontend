import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/core/data/enums/database_tables.dart';
import 'package:syncora_frontend/core/network/syncing/model/sync_payload.dart';

class SyncRepository {
  final Dio _dio;
  final DatabaseManager _databaseManager;

  final bool includeDeleted = true;

  SyncRepository({required Dio dio, required DatabaseManager databaseManager})
      : _dio = dio,
        _databaseManager = databaseManager;

  Future<SyncPayload> sync(String since) async {
    final response = await _dio
        .get(
          '${Constants.BASE_API_URL}/sync/$since?includeDeleted=$includeDeleted',
        )
        .timeout(const Duration(seconds: 10));
    // Logger().d(response.data);

    return SyncPayload.fromJson(response.data);
  }

  Future<void> storeSyncTimestamp(String timeStamp) async {
    Database db = await _databaseManager.getDatabase();
    await db.insert(DatabaseTables.syncTimestamps, {"timeStamp": timeStamp});
  }

  Future<String> getLastSyncTimestamp() async {
    Database db = await _databaseManager.getDatabase();
    var result =
        await db.query(DatabaseTables.syncTimestamps, orderBy: "id DESC");

    var timestamp = result.firstOrNull?["timestamp"];
    if (timestamp != null) return timestamp.toString();

    return "2010-01-01T15:29:34.033555Z";
  }
}

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/core/syncing/model/sync_payload.dart';

class SyncRepository {
  final Dio _dio;

  SyncRepository({required Dio dio}) : _dio = dio;

  Future<SyncPayload> sync(String since) async {
    final response = await _dio
        .get(
          '${Constants.BASE_URL}/sync/${since}T15:29:34.033555Z?includeDeleted=false',
        )
        .timeout(const Duration(seconds: 10));
    Logger().d(response.data);

    return SyncPayload.fromJson(response.data);
  }
}

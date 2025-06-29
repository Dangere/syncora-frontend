import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/syncing/model/sync_payload.dart';
import 'package:syncora_frontend/core/syncing/sync_repository.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';

class SyncService {
  final SyncRepository _syncRepository;

  SyncService({required SyncRepository syncRepository})
      : _syncRepository = syncRepository;

  Future<Result<SyncPayload>> syncFromServer() async {
    try {
      String lastSyncTimestamp = await _syncRepository.getLastSyncTimestamp();
      SyncPayload payload = await _syncRepository.sync(lastSyncTimestamp);

      await _syncRepository.storeSyncTimestamp(payload.timestamp);
      return Result.success(payload);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }
}

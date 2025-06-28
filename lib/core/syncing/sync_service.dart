import 'package:dio/dio.dart';
import 'package:logger/web.dart';
import 'package:syncora_frontend/core/syncing/model/sync_payload.dart';
import 'package:syncora_frontend/core/syncing/sync_repository.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/repositories/local_groups_repository.dart';
import 'package:syncora_frontend/features/groups/repositories/remote_groups_repository.dart';
import 'package:syncora_frontend/features/users/repositories/local_users_repository.dart';
import 'package:syncora_frontend/features/users/repositories/remote_users_repository.dart';

class SyncService {
  final SyncRepository _syncRepository;

  SyncService({required SyncRepository syncRepository})
      : _syncRepository = syncRepository;

  Future<Result<SyncPayload>> syncFromServer() async {
    try {
      SyncPayload payload = await _syncRepository.sync("2022-01-01");

      return Result.success(payload);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }
}

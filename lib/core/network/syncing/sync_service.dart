import 'package:syncora_frontend/core/network/syncing/model/sync_payload.dart';
import 'package:syncora_frontend/core/network/syncing/sync_repository.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/groups/services/groups_service.dart';
import 'package:syncora_frontend/features/users/services/users_service.dart';

class SyncService {
  final SyncRepository _syncRepository;
  final GroupsService _groupsService;
  final UsersService _usersService;

  SyncService(
      {required SyncRepository syncRepository,
      required GroupsService groupsService,
      required UsersService usersService})
      : _syncRepository = syncRepository,
        _groupsService = groupsService,
        _usersService = usersService;

  Future<Result<SyncPayload>> fetchPayload() async {
    try {
      String lastSyncTimestamp = await _syncRepository.getLastSyncTimestamp();
      SyncPayload payload = await _syncRepository.sync(lastSyncTimestamp);

      await _syncRepository.storeSyncTimestamp(payload.timestamp);
      return Result.success(payload);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> syncFromServer() async {
    Result<SyncPayload> result = await fetchPayload();

    if (!result.isSuccess) {
      return Result.failure(result.error!);
    }

    Result<void> upsertUsersResult =
        await _usersService.upsertUsers(result.data!.users);

    if (!upsertUsersResult.isSuccess) {
      return Result.failure(upsertUsersResult.error!);
    }

    Result<void> upsertGroupsResult =
        await _groupsService.upsertGroups(result.data!.groups);

    if (!upsertGroupsResult.isSuccess) {
      return Result.failure(upsertGroupsResult.error!);
    }
    // TODO: upsert tasks

    return Result.success(null);
  }
}

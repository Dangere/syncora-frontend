import 'package:syncora_frontend/core/network/syncing/model/sync_payload.dart';
import 'package:syncora_frontend/core/network/syncing/sync_repository.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/groups/repositories/local_groups_repository.dart';
import 'package:syncora_frontend/features/tasks/repositories/local_tasks_repository.dart';
import 'package:syncora_frontend/features/users/repositories/local_users_repository.dart';
import 'package:syncora_frontend/features/users/services/users_service.dart';

class SyncService {
  final SyncRepository _syncRepository;
  final LocalUsersRepository _localUsersRepository;
  final UsersService _usersService;
  final LocalGroupsRepository _localGroupsRepository;
  final LocalTasksRepository _localTasksRepository;

  SyncService(
      this._syncRepository,
      this._localGroupsRepository,
      this._localTasksRepository,
      this._localUsersRepository,
      this._usersService);

  Future<Result<SyncPayload>> fetchPayload() async {
    try {
      String lastSyncTimestamp = await _syncRepository.getLastSyncTimestamp();
      SyncPayload payload = await _syncRepository.sync(lastSyncTimestamp);

      await _syncRepository.storeSyncTimestamp(payload.timestamp);
      return Result.success(payload);
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  Future<Result<SyncPayload>> refreshFromServer() async {
    Result<SyncPayload> result = await fetchPayload();

    if (!result.isSuccess) {
      return result;
    }

    Result<void> processResult = await processPayload(result.data!);

    if (!processResult.isSuccess) {
      return Result.failure(processResult.error!.errorObject,
          processResult.error!.stackTrace ?? StackTrace.current);
    }

    return Result.success(result.data!);
  }

  Future<Result<void>> processPayload(SyncPayload payload) async {
    // Handling added users from payload
    try {
      await _localUsersRepository.upsertUsers(payload.users);
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }

    // Handling added groups from payload
    try {
      await _localGroupsRepository.upsertGroups(payload.groups);
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }

    // Handling added tasks from payload
    try {
      await _localTasksRepository.upsertTasks(payload.tasks);
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }

    // Handling kicked groups in payload
    try {
      for (var groupId in payload.kickedGroupsIds) {
        await _localGroupsRepository.markGroupAsDeleted(groupId);
        await _localGroupsRepository.wipeDeletedGroup(groupId);
      }
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }

    // Handling deleted groups in payload
    try {
      for (var groupId in payload.deletedGroups) {
        await _localGroupsRepository.markGroupAsDeleted(groupId);
        await _localGroupsRepository.wipeDeletedGroup(groupId);
      }
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }

    // Handling deleted tasks from payload
    try {
      for (var taskId in payload.deletedTasks) {
        await _localTasksRepository.markTaskAsDeleted(taskId);
        await _localTasksRepository.wipeDeletedTask(taskId);
      }
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }

    try {
      await _localUsersRepository.purgeOrphanedUsers();
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }

    return Result.success();
  }
}

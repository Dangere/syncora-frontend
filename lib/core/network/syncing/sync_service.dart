import 'package:syncora_frontend/core/network/syncing/model/sync_payload.dart';
import 'package:syncora_frontend/core/network/syncing/sync_repository.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/groups/repositories/local_groups_repository.dart';
import 'package:syncora_frontend/features/tasks/repositories/local_tasks_repository.dart';
import 'package:syncora_frontend/features/users/repositories/local_users_repository.dart';

class SyncService {
  final SyncRepository _syncRepository;
  final LocalUsersRepository _localUsersRepository;
  final LocalGroupsRepository _localGroupsRepository;
  final LocalTasksRepository _localTasksRepository;

  SyncService(this._syncRepository, this._localGroupsRepository,
      this._localTasksRepository, this._localUsersRepository);

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

  Future<Result<SyncPayload>> syncFromServer() async {
    Result<SyncPayload> result = await fetchPayload();

    if (!result.isSuccess) {
      return result;
    }

    // Handling added users from payload
    try {
      await _localUsersRepository.upsertUsers(result.data!.users);
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }

    // Handling added groups from payload
    try {
      await _localGroupsRepository.upsertGroups(result.data!.groups);
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }

    // Handling added tasks from payload
    try {
      await _localTasksRepository.upsertTasks(result.data!.tasks);
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }

    // Handling kicked groups in payload
    try {
      for (var groupId in result.data!.kickedGroupsIds!) {
        await _localGroupsRepository.markGroupAsDeleted(groupId);
        await _localGroupsRepository.wipeDeletedGroup(groupId);
      }
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }

    // Handling deleted groups in payload
    try {
      for (var groupId in result.data!.deletedGroups!) {
        await _localGroupsRepository.markGroupAsDeleted(groupId);
        await _localGroupsRepository.wipeDeletedGroup(groupId);
      }
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }

    // Handling deleted tasks from payload
    try {
      for (var taskId in result.data!.deletedTasks!) {
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

    return Result.success(result.data!);
  }
}

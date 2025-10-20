import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/network/outbox/interface/outbox_processor_interface.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_id_mapper.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';
import 'package:syncora_frontend/features/tasks/repositories/local_tasks_repository.dart';
import 'package:syncora_frontend/features/tasks/repositories/remote_tasks_repository.dart';

class TasksProcessor extends OutboxProcessor {
  final LocalTasksRepository _localTasksRepository;
  final RemoteTasksRepository _remoteTasksRepository;

  TasksProcessor(
      {required localTasksRepository,
      required remoteTasksRepository,
      required super.idMapper,
      required super.delayBeforeSyncReattempt,
      required super.logger})
      : _localTasksRepository = localTasksRepository,
        _remoteTasksRepository = remoteTasksRepository;

  @override
  Future<Result<int>> processOutbox(OutboxEntry entry) async {
    // Everytime we call getServerId, we are SURE that temp id is already synced to server
    Result groupIdResult = await idMapper.getServerId(entry.entityId);
    if (!groupIdResult.isSuccess) return Result.failure(groupIdResult.error!);
    int groupId = groupIdResult.data;

    int? taskId;
    if (entry.actionType != OutboxActionType.create) {
      Result result = await idMapper.getServerId(entry.entityId);
      if (!result.isSuccess) return Result.failure(result.error!);
      taskId = result.data;
    }

    // This will keep processing the entry until its complete or rejected with 401
    while (true) {
      try {
        switch (entry.actionType) {
          // The create event
          case OutboxActionType.create:
            {
              Task newTask = await _remoteTasksRepository.createTask(
                  title: entry.payload['title'],
                  description: entry.payload['description'],
                  groupId: groupId);

              await _localTasksRepository.updateTaskId(
                  entry.entityId, newTask.id);
              idMapper.cacheId(tempId: entry.entityId, serverId: newTask.id);
              return Result.success(groupId);
            }
          // The update event
          case OutboxActionType.update:
            {
              await _remoteTasksRepository.updateTask(
                  title: entry.payload['title'],
                  description: entry.payload['description'],
                  taskId: taskId!,
                  groupId: groupId);
              return Result.success(groupId);
            }
          // The delete event
          case OutboxActionType.delete:
            {
              await _remoteTasksRepository.deleteTask(
                  taskId: taskId!, groupId: groupId);
              return Result.success(groupId);
            }
          default:
            return Result.success(groupId);
        }
      } on DioException catch (e, stackTrace) {
        // If the status code is not 403, we wait and try again
        if (e.response?.statusCode != 403) {
          await Future.delayed(delayBeforeSyncReattempt);
          continue;
        } else {
          // If the status code is 403 we fail the action and revert
          logger.d(
              "Outbox task processor failed to sync entity ${entry.toTable()}, with status code: ${e.response?.statusCode}. Attempting to revert local action");

          return Result.failure(ErrorMapper.map(e, stackTrace));
        }
      } // If not an http error we return the error and fail action and revert
      catch (e, stackTrace) {
        logger.d(
            "Outbox task processor failed to sync entity ${entry.toTable()}, fatal error. Attempting to revert local action");

        return Result.failure(ErrorMapper.map(e, stackTrace));
      }
    }
  }

  @override
  Future<Result<int>> revertProcess(OutboxEntry entry) async {
    // int? groupId;
    // if (entry.actionType != OutboxActionType.create) {
    //   // Everytime we call getServerId, we are SURE that temp id is already synced to server
    //   Result result = await idMapper.getServerId(entry.entityId);
    //   if (!result.isSuccess) return Result.failure(result.error!);
    //   groupId = result.data;
    // }

    try {
      switch (entry.actionType) {
        case OutboxActionType.create:
          // TODO: Handle this case.

          break;
        case OutboxActionType.update:
          // TODO: Handle this case.

          break;
        case OutboxActionType.delete:
          // TODO: Handle this case.
          break;
        default:
      }

      return Result.success(1);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }
}

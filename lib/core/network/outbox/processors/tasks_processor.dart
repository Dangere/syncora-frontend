import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:syncora_frontend/core/network/outbox/exception/outbox_exception.dart';
import 'package:syncora_frontend/core/network/outbox/interface/outbox_processor_interface.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_payload.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
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

  // To process a task entry, we always need a synced group id
  // To process a task deletion/update/mark, we need a synced group id and a synced task id
  // Failing to get a dependency means we should skip processing the entry and skip reverting it

  // Creation process should ALWAYS cache the server id when successful for future processing
  @override
  Future<int> processOutbox(OutboxEntry entry) async {
    // Getting our mandatory group id dependency

    switch (entry.payload!) {
      case OutboxTaskPayload():
        break;
      default:
    }

    Result groupIdResult =
        await idMapper.getServerId(entry.payload!.asOutboxTaskPayload!.groupId);
    if (!groupIdResult.isSuccess) {
      throw OutboxDependencyFailureException(
          "Group dependency failed to get, entry: ${entry.toTable()}");
    }
    int groupId = groupIdResult.data!;

    // To process a task deletion/updating/marking we get our mandatory task id dependency
    int? taskId;
    if (entry.actionType != OutboxActionType.create) {
      Result taskIdResult = await idMapper.getServerId(entry.entityId);
      if (!groupIdResult.isSuccess) {
        throw OutboxDependencyFailureException(
            "Task dependency failed to get, entry: ${entry.toTable()}");
      }
      // If we have no server id, we are processing a create event
      taskId = taskIdResult.isSuccess ? taskIdResult.data : null;
    }

    switch (entry.actionType) {
      // The create event
      case OutboxActionType.create:
        {
          Task newTask = await _remoteTasksRepository.createTask(
              title: entry.payload!.asCreateTaskPayload!.title,
              description: entry.payload!.asCreateTaskPayload!.description,
              groupId: groupId);

          await _localTasksRepository.updateTaskId(entry.entityId, newTask.id);
          idMapper.cacheId(tempId: entry.entityId, serverId: newTask.id);
          return groupId;
        }
      // The update event
      case OutboxActionType.update:
        {
          await _remoteTasksRepository.updateTask(
              title: entry.payload!.asUpdateTaskPayload!.title,
              description: entry.payload!.asUpdateTaskPayload!.description,
              taskId: taskId!,
              groupId: groupId);
          return groupId;
        }
      // The delete event
      case OutboxActionType.delete:
        {
          await _remoteTasksRepository.deleteTask(
              taskId: taskId!, groupId: groupId);
          return groupId;
        }
      default:
        return groupId;
    }
  }

  // This wont be called if dependencies are not met
  @override
  Future<int> revertProcess(OutboxEntry entry) async {
    switch (entry.actionType) {
      // case OutboxActionType.create:
      //   await _localTasksRepository.markTaskAsDeleted(entry.entityId);
      //   return Result.success(groupId);
      case OutboxActionType.update:
        // TODO: Handle this case.

        break;
      case OutboxActionType.delete:
        // TODO: Handle this case.
        break;

      case OutboxActionType.mark:
        // TODO: Handle this case.
        break;

      case OutboxActionType.leave:
        // TODO: Handle this case.
        break;
      default:
    }

    return 0;
  }
}

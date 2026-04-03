import 'package:syncora_frontend/core/network/outbox/model/enqueue_request.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_payload.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';
import 'package:syncora_frontend/features/tasks/repositories/local_tasks_repository.dart';
import 'package:syncora_frontend/features/tasks/repositories/remote_tasks_repository.dart';
import 'package:syncora_frontend/features/tasks/tasks_provider.dart';

class TasksService {
  final LocalTasksRepository _localTasksRepository;
  final RemoteTasksRepository _remoteTasksRepository;
  final AsyncFunc<EnqueueRequest, Result<void>> _enqueueEntry;

  final AuthState Function() _authStateFactory;
  TasksService(this._localTasksRepository, this._remoteTasksRepository,
      {required Future<Result<void>> Function(EnqueueRequest) enqueueEntry,
      required AuthState Function() authStateFactory})
      : _enqueueEntry = enqueueEntry,
        _authStateFactory = authStateFactory;

  Future<Result<List<Task>>> getTasksForGroup(
      int groupId, List<TaskFilter> filters) async {
    try {
      // We aren't checking if user is authenticated or not because guests and logged in users can access tasks
      List<Task> tasks = await _localTasksRepository.getTasksForGroup(
          groupId, _authStateFactory().userId!, filters);
      return Result.success(tasks);
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  Future<Result<void>> deleteTask(
      {required int taskId, required int groupId}) async {
    Result enqueueResult = await _enqueueEntry(EnqueueRequest(
      entry: OutboxEntry.entry(
        entityId: taskId,
        dependencyId: groupId,
        entityType: OutboxEntityType.task,
        actionType: OutboxActionType.delete,
      ),
      onAfterEnqueue: () async {
        try {
          await _localTasksRepository.markTaskAsDeleted(taskId);
          return Result.success();
        } catch (e, stackTrace) {
          return Result.failure(e, stackTrace);
        }
      },
    ));

    if (!enqueueResult.isSuccess && !enqueueResult.isCancelled)
      return enqueueResult;

    return Result.success();
  }

  Future<Result<void>> updateTask(
      {required int taskId,
      required int groupId,
      String? title,
      String? description}) async {
    Task task = await _localTasksRepository.getTask(taskId);

    Result enqueueResult = await _enqueueEntry(EnqueueRequest(
      entry: OutboxEntry.entry(
        entityId: taskId,
        dependencyId: groupId,
        entityType: OutboxEntityType.task,
        actionType: OutboxActionType.update,
        payload: UpdateTaskPayload(
            title: title,
            description: description,
            oldTitle: task.title,
            oldDescription: task.description),
      ),
      onAfterEnqueue: () async {
        try {
          await _localTasksRepository.updateTaskDetails(
              taskId: taskId, title: title, description: description);
          return Result.success();
        } catch (e, stackTrace) {
          return Result.failure(e, stackTrace);
        }
      },
    ));
    if (!enqueueResult.isSuccess && !enqueueResult.isCancelled)
      return enqueueResult;

    return Result.success();
  }

  Future<Result<void>> createTask(
      {required String title,
      String? description,
      required int groupId}) async {
    final now = DateTime.now().toUtc();

    Task task = Task(
        id: -now.millisecondsSinceEpoch,
        title: title,
        description: description,
        groupId: groupId,
        creationDate: now,
        completedById: null,
        assignedTo: []);

    Result enqueueResult = await _enqueueEntry(EnqueueRequest(
      entry: OutboxEntry.entry(
        entityId: task.id,
        dependencyId: groupId,
        entityType: OutboxEntityType.task,
        actionType: OutboxActionType.create,
        payload: CreateTaskPayload(title: title, description: description),
      ),
      onAfterEnqueue: () async {
        try {
          await _localTasksRepository.upsertTasks([task]);
          return Result.success();
        } catch (e, stackTrace) {
          return Result.failure(e, stackTrace);
        }
      },
    ));

    if (!enqueueResult.isSuccess && !enqueueResult.isCancelled)
      return enqueueResult;

    return Result.success();
  }

  Future<Result<void>> assignTaskToUsers(
      {required int taskId,
      required int groupId,
      required List<int> ids}) async {
    if (_authStateFactory().isGuest || _authStateFactory().isUnauthenticated) {
      return Result.failureMessage(
          "Can't assign task to users when not logged in");
    }
    try {
      return Result.success(await _remoteTasksRepository.assignTask(
          taskId: taskId, groupId: groupId, ids: ids));
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  Future<Result<void>> setAssignedUsersToTask(
      {required int taskId,
      required int groupId,
      required List<int> ids}) async {
    if (_authStateFactory().isGuest || _authStateFactory().isUnauthenticated) {
      return Result.failureMessage(
          "Can't assign task to users when not logged in");
    }
    try {
      return Result.success(await _remoteTasksRepository.setAssignTask(
          taskId: taskId, groupId: groupId, ids: ids));
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  Future<Result<void>> markTask(
      {required int taskId, required int groupId, required bool isDone}) async {
    Result enqueueResult = await _enqueueEntry(EnqueueRequest(
      entry: OutboxEntry.entry(
        entityId: taskId,
        dependencyId: groupId,
        entityType: OutboxEntityType.task,
        actionType: OutboxActionType.mark,
        payload: MarkTaskPayload(
            completedById: _authStateFactory().userId!, isCompleted: isDone),
      ),
      onAfterEnqueue: () async {
        try {
          await _localTasksRepository.markTaskCompletion(
              taskId: taskId,
              userId: _authStateFactory().userId!,
              isDone: isDone);
          return Result.success();
        } catch (e, stackTrace) {
          return Result.failure(e, stackTrace);
        }
      },
    ));

    if (!enqueueResult.isSuccess && !enqueueResult.isCancelled)
      return enqueueResult;

    return Result.success();
  }
}

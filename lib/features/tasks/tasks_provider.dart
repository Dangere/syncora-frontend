import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_provider.dart';
import 'package:syncora_frontend/core/network/syncing/sync_state.dart';
import 'package:syncora_frontend/core/network/syncing/sync_provider.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/groups/groups_provider.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';
import 'package:syncora_frontend/features/tasks/repositories/local_tasks_repository.dart';
import 'package:syncora_frontend/features/tasks/repositories/remote_tasks_repository.dart';
import 'package:syncora_frontend/features/tasks/services/tasks_service.dart';

final localTasksRepositoryProvider = Provider<LocalTasksRepository>((ref) {
  return LocalTasksRepository(ref.watch(localDbProvider));
});

final remoteTasksRepositoryProvider = Provider<RemoteTasksRepository>((ref) {
  return RemoteTasksRepository(dio: ref.watch(dioProvider));
});

final tasksServiceProvider = Provider<TasksService>((ref) {
  return TasksService(
    authState: ref.watch(authProvider).asData!.value,
    localTasksRepository: ref.watch(localTasksRepositoryProvider),
    remoteTasksRepository: ref.watch(remoteTasksRepositoryProvider),
    enqueueEntry: (enqueueRequest) =>
        ref.read(outboxProvider.notifier).enqueue(enqueueRequest),
  );
});

// This notifier is used to load tasks for a specific group
// It updates the UI when a method to modify tasks is called
// Or when the sync state changes
// It does NOT listen to changes to the group itself to avoid unnecessary rebuilds

// TODO: Since there is not direct conneciton between the tasks and the groups notifier, creating a task
// Does not update the groups notifier to reflect it in the dashboard UI
class TasksNotifier extends AutoDisposeFamilyAsyncNotifier<List<Task>, int> {
  List<TaskFilter> get filters => _filters;

  List<TaskFilter> _filters = [TaskFilter.pending];

  Future<void> createTask(
      {required String title, required String? description}) async {
    ref.read(loggerProvider).d("Creating task");
    Result<void> createResult = await ref
        .read(tasksServiceProvider)
        .createTask(title: title, description: description, groupId: arg);

    if (!createResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = createResult.error;
      return;
    }
    _reloadTasks();

    // _reloadGroupsList();
    // reloadViewedGroups([groupId]);
  }

  Future<void> deleteTask({required int taskId}) async {
    Result<void> deleteResult = await ref
        .read(tasksServiceProvider)
        .deleteTask(groupId: arg, taskId: taskId);

    if (!deleteResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = deleteResult.error;
      return;
    }
    _reloadTasks();

    // _reloadGroupsList();
    // reloadViewedGroups([groupId]);
  }

  Future<void> updateTask(
      {required int taskId, String? title, String? description}) async {
    Result<void> updateResult = await ref.read(tasksServiceProvider).updateTask(
        groupId: arg, taskId: taskId, title: title, description: description);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }
    _reloadTasks();

    // reloadViewedGroups([groupId]);
  }

  Future<void> assignTask({required int taskId, required List<int> ids}) async {
    Result<void> updateResult = await ref
        .read(tasksServiceProvider)
        .assignTaskToUsers(groupId: arg, taskId: taskId, ids: ids);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }
    _reloadTasks();
  }

  Future<void> setAssignTask(
      {required int taskId, required List<int> ids}) async {
    Result<void> updateResult = await ref
        .read(tasksServiceProvider)
        .setAssignedUsersToTask(taskId: taskId, groupId: arg, ids: ids);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }
    _reloadTasks();
  }

  Future<void> markTask({required int taskId, required bool isDone}) async {
    Result<void> updateResult = await ref
        .read(tasksServiceProvider)
        .markTask(taskId: taskId, groupId: arg, isDone: isDone);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }
    _reloadTasks();
    // reloadViewedGroups([groupId]);
  }

  Future<void> filterTasks(List<TaskFilter> tasksFilters) async {
    if (state.isLoading) {
      return;
    }
    _filters = tasksFilters;
    _reloadTasks();
  }

  void _reloadTasks() async {
    ref
        .read(loggerProvider)
        .d("Tasks provider: Reloading tasks for group $arg");

    Result<List<Task>> result =
        await ref.read(tasksServiceProvider).getTasksForGroup(arg, _filters);

    if (result.isSuccess) {
      state = AsyncValue.data(result.data!);
    } else {
      state = AsyncValue.error(result.error!.errorObject,
          result.error!.stackTrace ?? StackTrace.current);
    }
  }

  @override
  FutureOr<List<Task>> build(int groupId) async {
    // Updating the UI on remote task changes
    ref.listen(syncBackendProvider, (previous, next) {
      // If there is no error and the payload is not null in the next value, then we have a new payload
      if (next.error == null && !next.isLoading && next.value != null) {
        // Checking if the payload is empty or still in progress (loading)
        if (!next.value!.isAvailable || next.value!.payload!.isEmpty()) return;

        // Reloading on deleted tasks
        for (int taskId in next.value!.payload!.deletedTasks) {
          if (state.value!.where((t) => t.id == taskId).isNotEmpty) {
            _reloadTasks();
          }
        }

        // Reloading on new tasks
        if (next.value!.payload!.tasks
            .where((t) => t.groupId == groupId)
            .isNotEmpty) {
          _reloadTasks();
        }
      }
    });

    ref
        .read(loggerProvider)
        .d("Tasks provider: Loading tasks for group $groupId");

    Result<List<Task>> result = await ref
        .read(tasksServiceProvider)
        .getTasksForGroup(groupId, _filters);

    if (result.isSuccess) {
      return result.data!;
    } else {
      ref.read(appErrorProvider.notifier).state = result.error!;
      return [];
    }
  }
}

final tasksProvider = AsyncNotifierProvider.autoDispose
    .family<TasksNotifier, List<Task>, int>(TasksNotifier.new);

enum TaskFilter { pending, completed, assigned, newest, oldest }

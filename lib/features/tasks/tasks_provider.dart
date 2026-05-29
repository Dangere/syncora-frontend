import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/analytics/breadcrumb_type.dart';
import 'package:syncora_frontend/core/analytics/breadcrumbs_service.dart';
import 'package:syncora_frontend/core/error_management/error_provider.dart';
import 'package:syncora_frontend/features/tasks/tasks_filter.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_provider.dart';
import 'package:syncora_frontend/core/network/syncing/sync_state.dart';
import 'package:syncora_frontend/core/network/syncing/sync_provider.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/groups/groups_provider.dart';
import 'package:syncora_frontend/features/tasks/task.dart';
import 'package:syncora_frontend/features/tasks/repositories/local_tasks_repository.dart';
import 'package:syncora_frontend/features/tasks/repositories/remote_tasks_repository.dart';
import 'package:syncora_frontend/features/tasks/tasks_service.dart';

final localTasksRepositoryProvider = Provider<LocalTasksRepository>((ref) {
  return LocalTasksRepository(ref.watch(localDbProvider));
});

final remoteTasksRepositoryProvider = Provider<RemoteTasksRepository>((ref) {
  return RemoteTasksRepository(dio: ref.watch(dioProvider));
});

final tasksServiceProvider = Provider<TasksService>((ref) {
  return TasksService(
    ref.watch(localTasksRepositoryProvider),
    ref.watch(remoteTasksRepositoryProvider),
    enqueueEntry: (enqueueRequest) =>
        ref.read(outboxProvider.notifier).enqueue(enqueueRequest),
    authState: () => ref.read(authStateProvider),
  );
});

// This notifier is used to load tasks for a specific group
// It updates the UI when a method to modify tasks is called
// Or when the sync state changes
// It does NOT listen to changes to the group itself to avoid unnecessary rebuilds HOWEVER the group notifier can trigger it to update

// TODO(DONE): Since there is not direct conneciton between the tasks and the groups notifier, creating a task
// Does not update the groups notifier to reflect it in the dashboard UI
class TasksNotifier extends AutoDisposeFamilyAsyncNotifier<List<Task>, int> {
  List<TasksFilter> get filters => _filters;

  List<TasksFilter> _filters = [TasksFilter.all, TasksFilter.newest];
  int get _groupResolvedId => ref.read(outboxIdMapperProvider).resolveId(arg);

  bool get isGroupOwner => ref.read(groupProvider(arg).notifier).isGroupOwner();

  Future<void> createTask(
      {required String title, required String? description}) async {
    ref.read(loggerProvider).d("Creating task");
    Result<void> createResult = await ref.read(tasksServiceProvider).createTask(
        title: title, description: description, groupId: _groupResolvedId);

    if (!createResult.isSuccess && !createResult.isCancelled) {
      ref.read(appErrorProvider.notifier).setError(createResult.error!);
      return;
    }
    _reloadTasks();
    ref.read(groupsListProvider.notifier).onTasksModification(_groupResolvedId);

    BreadcrumbService.instance
        .add(BreadcrumbType.state, "Task $title, created");

    // _reloadGroupsList();
    // reloadViewedGroups([groupId]);
  }

  Future<void> deleteTask({required int taskId}) async {
    //Checking if user is not the owner of the group
    if (!isGroupOwner) return;

    int resolvedId = ref.read(outboxIdMapperProvider).resolveId(taskId);

    Result<void> deleteResult = await ref
        .read(tasksServiceProvider)
        .deleteTask(groupId: _groupResolvedId, taskId: resolvedId);

    if (!deleteResult.isSuccess && !deleteResult.isCancelled) {
      ref.read(appErrorProvider.notifier).setError(deleteResult.error!);
      return;
    }
    _reloadTasks();

    ref.read(groupsListProvider.notifier).onTasksModification(_groupResolvedId);

    BreadcrumbService.instance
        .add(BreadcrumbType.state, "Task $resolvedId, deleted");
    // _reloadGroupsList();
    // reloadViewedGroups([groupId]);
  }

  Future<void> updateTask(
      {required int taskId, String? title, String? description}) async {
    int resolvedId = ref.read(outboxIdMapperProvider).resolveId(taskId);

    Result<void> updateResult = await ref.read(tasksServiceProvider).updateTask(
        groupId: _groupResolvedId,
        taskId: resolvedId,
        title: title,
        description: description);

    if (!updateResult.isSuccess && !updateResult.isCancelled) {
      ref.read(appErrorProvider.notifier).setError(updateResult.error!);
      return;
    }
    _reloadTasks();

    ref.read(groupsListProvider.notifier).onTasksModification(_groupResolvedId);

    BreadcrumbService.instance
        .add(BreadcrumbType.state, "Task $resolvedId, updated");
    // reloadViewedGroups([groupId]);
  }

  Future<void> setAssignTask(
      {required int taskId, required List<int> ids}) async {
    int resolvedId = ref.read(outboxIdMapperProvider).resolveId(taskId);

    Result<void> updateResult = await ref
        .read(tasksServiceProvider)
        .setAssignedUsersToTask(
            taskId: resolvedId, groupId: _groupResolvedId, ids: ids);

    if (!updateResult.isSuccess && !updateResult.isCancelled) {
      ref.read(appErrorProvider.notifier).setError(updateResult.error!);
      return;
    }
    _reloadTasks();
  }

  Future<void> markTask({required Task task, required bool isDone}) async {
    //Checking if user is not the owner of the group
    if (!isGroupOwner) {
      //Checking if user is not assigned to task
      if (!task.assignedTo.contains(_userId())) {
        return;
      }
    }

    int resolvedId = ref.read(outboxIdMapperProvider).resolveId(task.id);

    Result<void> updateResult = await ref.read(tasksServiceProvider).markTask(
        taskId: resolvedId, groupId: _groupResolvedId, isDone: isDone);

    if (!updateResult.isSuccess && !updateResult.isCancelled) {
      ref.read(appErrorProvider.notifier).setError(updateResult.error!);
      return;
    }
    _reloadTasks();
    ref.read(groupsListProvider.notifier).onTasksModification(_groupResolvedId);
    BreadcrumbService.instance.add(BreadcrumbType.state,
        "Task $resolvedId, ${isDone ? "marked" : "unmarked"}");
    // reloadViewedGroups([groupId]);
  }

  Future<void> filterTasks(List<TasksFilter> tasksFilters) async {
    if (state.isLoading) {
      return;
    }
    _filters = tasksFilters;
    _reloadTasks(isFiltering: true);
  }

  void _reloadTasks({bool isFiltering = false}) async {
    ref
        .read(loggerProvider)
        .d("Tasks provider: Reloading tasks for group $_groupResolvedId");

    // If we are just reloading to filter, we dont ask the groups list provider to update itself
    if (!isFiltering) ref.read(groupsListProvider.notifier).reloadGroupsList();

    Result<List<Task>> result = await ref
        .read(tasksServiceProvider)
        .getTasksForGroup(_groupResolvedId, _filters);

    if (!result.isSuccess && !result.isCancelled) {
      ref.read(appErrorProvider.notifier).setError(result.error!);
    } else {
      state = AsyncValue.data(result.data!);
    }
  }

  int _userId() {
    return ref.read(authProvider).value!.userId!;
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
            .where((t) => t.groupId == _groupResolvedId)
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
        .getTasksForGroup(_groupResolvedId, _filters);

    if (result.isSuccess && !result.isCancelled) {
      return result.data!;
    } else {
      ref.read(appErrorProvider.notifier).setError(result.error!);
      return [];
    }
  }
}

final tasksProvider = AsyncNotifierProvider.autoDispose
    .family<TasksNotifier, List<Task>, int>(TasksNotifier.new);

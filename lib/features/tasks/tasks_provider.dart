import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_provider.dart';
import 'package:syncora_frontend/core/network/syncing/sync_state.dart';
import 'package:syncora_frontend/core/network/syncing/sync_provider.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/users/models/user.dart';
import 'package:syncora_frontend/features/groups/groups_provider.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';
import 'package:syncora_frontend/features/tasks/repositories/local_tasks_repository.dart';
import 'package:syncora_frontend/features/tasks/repositories/remote_tasks_repository.dart';
import 'package:syncora_frontend/features/tasks/services/tasks_service.dart';
import 'package:syncora_frontend/features/users/providers/users_provider.dart';

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
    authStateFactory: () => ref.read(authStateProvider),
  );
});

// final tasksViewGetterProvider =
//     FutureProvider.family.autoDispose<List<Task>?, int>((ref, id) async {
//   try {
//     return await ref.read(localGroupsRepositoryProvider).getGroup(id);
//   } catch (e) {
//     return null;
//   }
// });

// This notifier is used to load tasks for a specific group
// It updates the UI when a method to modify tasks is called
// Or when the sync state changes
// It does NOT listen to changes to the group itself to avoid unnecessary rebuilds

// TODO: Since there is not direct conneciton between the tasks and the groups notifier, creating a task
// Does not update the groups notifier to reflect it in the dashboard UI
class TasksNotifier extends AutoDisposeFamilyAsyncNotifier<List<Task>, int> {
  List<TaskFilter> get filters => _filters;

  List<TaskFilter> _filters = [TaskFilter.all];
  int get _groupResolvedId => ref.read(outboxIdMapperProvider).resolveId(arg);

  bool get isGroupOwner => ref.read(groupProvider(arg).notifier).isGroupOwner();

  Future<void> createTask(
      {required String title, required String? description}) async {
    ref.read(loggerProvider).d("Creating task");
    Result<void> createResult = await ref.read(tasksServiceProvider).createTask(
        title: title, description: description, groupId: _groupResolvedId);

    if (!createResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = createResult.error;
      return;
    }
    reloadTasks();
    ref.read(groupsListProvider.notifier).onTasksModification(_groupResolvedId);

    // _reloadGroupsList();
    // reloadViewedGroups([groupId]);
  }

  Future<void> deleteTask({required int taskId}) async {
    //Checking if user is not the owner of the group
    if (!isGroupOwner) return;

    Result<void> deleteResult = await ref
        .read(tasksServiceProvider)
        .deleteTask(groupId: _groupResolvedId, taskId: taskId);

    if (!deleteResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = deleteResult.error;
      return;
    }
    reloadTasks();

    ref.read(groupsListProvider.notifier).onTasksModification(_groupResolvedId);

    // _reloadGroupsList();
    // reloadViewedGroups([groupId]);
  }

  Future<void> updateTask(
      {required int taskId, String? title, String? description}) async {
    Result<void> updateResult = await ref.read(tasksServiceProvider).updateTask(
        groupId: _groupResolvedId,
        taskId: taskId,
        title: title,
        description: description);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }
    reloadTasks();

    ref.read(groupsListProvider.notifier).onTasksModification(_groupResolvedId);

    // reloadViewedGroups([groupId]);
  }

  Future<void> assignTask({required int taskId, required List<int> ids}) async {
    Result<void> updateResult = await ref
        .read(tasksServiceProvider)
        .assignTaskToUsers(groupId: _groupResolvedId, taskId: taskId, ids: ids);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }
    reloadTasks();
  }

  Future<List<User>> assignedUsers(int taskId) async {
    List<int> assignedUsersIds = !state.hasValue
        ? []
        : state.value!.where((t) => taskId == t.id).first.assignedTo;

    Result<List<User>> usersResult =
        await ref.read(usersServiceProvider).getCachedUsers(assignedUsersIds);

    if (!usersResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = usersResult.error;
      return [];
    }

    return usersResult.data!;
  }

  Future<void> setAssignTask(
      {required int taskId, required List<int> ids}) async {
    Result<void> updateResult = await ref
        .read(tasksServiceProvider)
        .setAssignedUsersToTask(
            taskId: taskId, groupId: _groupResolvedId, ids: ids);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }
    reloadTasks();
  }

  Future<void> markTask({required Task task, required bool isDone}) async {
    //Checking if user is not the owner of the group
    if (!isGroupOwner) {
      //Checking if user is not assigned to task
      if (!task.assignedTo.contains(_userId())) {
        return;
      }
    }

    Result<void> updateResult = await ref
        .read(tasksServiceProvider)
        .markTask(taskId: task.id, groupId: _groupResolvedId, isDone: isDone);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }
    reloadTasks();
    ref.read(groupsListProvider.notifier).onTasksModification(_groupResolvedId);

    // reloadViewedGroups([groupId]);
  }

  Future<void> filterTasks(List<TaskFilter> tasksFilters) async {
    if (state.isLoading) {
      return;
    }
    _filters = tasksFilters;
    reloadTasks();
  }

  void reloadTasks() async {
    ref
        .read(loggerProvider)
        .d("Tasks provider: Reloading tasks for group $_groupResolvedId");

    Result<List<Task>> result = await ref
        .read(tasksServiceProvider)
        .getTasksForGroup(_groupResolvedId, _filters);

    if (result.isSuccess) {
      state = AsyncValue.data(result.data!);
    } else {
      state =
          AsyncValue.error(result.error!.errorObject, result.error!.stackTrace);
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
            reloadTasks();
          }
        }

        // Reloading on new tasks
        if (next.value!.payload!.tasks
            .where((t) => t.groupId == _groupResolvedId)
            .isNotEmpty) {
          reloadTasks();
        }
      }
    });

    ref
        .read(loggerProvider)
        .d("Tasks provider: Loading tasks for group $groupId");

    Result<List<Task>> result = await ref
        .read(tasksServiceProvider)
        .getTasksForGroup(_groupResolvedId, _filters);

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

enum TaskFilter { all, pending, completed, assigned, newest, oldest }

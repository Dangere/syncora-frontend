import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_viewmodel.dart';
import 'package:syncora_frontend/core/network/syncing/sync_state.dart';
import 'package:syncora_frontend/core/network/syncing/sync_viewmodel.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';
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
    authState: ref.watch(authNotifierProvider).asData!.value,
    localTasksRepository: ref.watch(localTasksRepositoryProvider),
    remoteTasksRepository: ref.watch(remoteTasksRepositoryProvider),
    enqueueEntry: (enqueueRequest) =>
        ref.read(outboxProvider.notifier).enqueue(enqueueRequest),
  );
});

class TasksNotifier extends AutoDisposeFamilyAsyncNotifier<List<Task>, int> {
  void reloadTasks(int groupId) async {
    ref
        .read(loggerProvider)
        .d("Tasks provider: Reloading tasks for group $groupId");

    Result<List<Task>> result =
        await ref.read(tasksServiceProvider).getTasksForGroup(groupId);

    if (result.isSuccess) {
      state = AsyncValue.data(result.data!);
    } else {
      state = AsyncValue.error(result.error!.errorObject,
          result.error!.stackTrace ?? StackTrace.current);
    }
  }

  @override
  FutureOr<List<Task>> build(int groupId) async {
    // Updating the UI on group's tasks changes
    ref.listen(syncBackendNotifierProvider, (previous, next) {
      // If there is no error and the payload is not null in the next value, then we have a new payload
      if (next.error == null && !next.isLoading && next.value != null) {
        // Checking if the payload is empty or still in progress (loading)
        if (!next.value!.isAvailable || next.value!.payload!.isEmpty()) return;

        // Reloading on deleted tasks
        for (int taskId in next.value!.payload!.deletedTasks) {
          if (state.value!.where((t) => t.id == taskId).isNotEmpty) {
            reloadTasks(groupId);
          }
        }

        // Reloading on new tasks
        if (next.value!.payload!.tasks
            .where((t) => t.groupId == groupId)
            .isNotEmpty) {
          reloadTasks(groupId);
        }
      }
    });

    ref
        .read(loggerProvider)
        .d("Tasks provider: Loading tasks for group $groupId");

    Result<List<Task>> result =
        await ref.read(tasksServiceProvider).getTasksForGroup(groupId);

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

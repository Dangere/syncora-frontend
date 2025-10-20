import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_viewmodel.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/repositories/local_groups_repository.dart';
import 'package:syncora_frontend/features/groups/repositories/remote_groups_repository.dart';
import 'package:syncora_frontend/features/groups/services/groups_service.dart';
import 'package:syncora_frontend/features/tasks/viewmodel/tasks_providers.dart';

class GroupsNotifier extends AsyncNotifier<List<Group>> {
  Future<void> createGroup(String title, String description) async {
    // state = const AsyncValue.loading();

    Result<Group> newGroupResult =
        await ref.read(groupsServiceProvider).createGroup(title, description);

    if (!newGroupResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = newGroupResult.error;
      return;
    }

    reloadGroups();
  }

  Future<void> updateGroupDetails(
      String? title, String? description, int groupId) async {
    if (title == null && description == null) return;

    ref.read(loggerProvider).d("Updating group details");
    Result<void> updateResult = await ref
        .read(groupsServiceProvider)
        .updateGroupDetails(title, description, groupId);
    ref.read(loggerProvider).d("Done updating group details");

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }

    reloadGroups();
    reloadViewedGroup(groupId);
  }

  Future<void> allowUserAccessToGroup(
      {required int groupId, required String username}) async {
    Result<void> updateResult = await ref
        .read(groupsServiceProvider)
        .grantAccessToGroup(
            allowAccess: true, groupId: groupId, username: username);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }
  }

  Future<void> removeUserAccessToGroup(
      {required int groupId, required String username}) async {
    Result<void> updateResult = await ref
        .read(groupsServiceProvider)
        .grantAccessToGroup(
            allowAccess: false, groupId: groupId, username: username);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }
  }

  Future<void> createTask(
      {required int groupId,
      required String title,
      required String? description}) async {
    Result<void> createResult = await ref
        .read(tasksServiceProvider)
        .createTask(title: title, description: description, groupId: groupId);

    if (!createResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = createResult.error;
      return;
    }

    reloadViewedGroup(groupId);
  }

  Future<void> deleteTask({required int taskId, required int groupId}) async {
    Result<void> deleteResult = await ref
        .read(tasksServiceProvider)
        .deleteTask(groupId: groupId, taskId: taskId);

    if (!deleteResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = deleteResult.error;
      return;
    }
    reloadViewedGroup(groupId);
  }

  Future<void> updateTask(
      {required int taskId,
      required int groupId,
      String? title,
      String? description}) async {
    Result<void> updateResult = await ref.read(tasksServiceProvider).updateTask(
        groupId: groupId,
        taskId: taskId,
        title: title,
        description: description);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }

    reloadViewedGroup(groupId);
  }

  Future<void> assignTask(
      {required int taskId,
      required int groupId,
      required List<int> ids}) async {
    Result<void> updateResult = await ref
        .read(tasksServiceProvider)
        .assignTaskToUsers(groupId: groupId, taskId: taskId, ids: ids);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }
  }

  Future<void> setAssignTask(
      {required int taskId,
      required int groupId,
      required List<int> ids}) async {
    Result<void> updateResult = await ref
        .read(tasksServiceProvider)
        .setAssignedUsersToTask(taskId: taskId, groupId: groupId, ids: ids);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }
  }

  Future<void> markTask(
      {required int taskId, required int groupId, required bool isDone}) async {
    Result<void> updateResult = await ref
        .read(tasksServiceProvider)
        .markTask(taskId: taskId, groupId: groupId, isDone: isDone);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }
    reloadViewedGroup(groupId);
  }

  Future<void> reloadGroups() async {
    Result<List<Group>> fetchResult =
        await ref.read(groupsServiceProvider).getAllGroups();

    if (!fetchResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = fetchResult.error;
    }

    state = AsyncValue.data(fetchResult.data!);
  }

  // Takes in an id of a group that was modified to check if it's 're currently displayed then refresh the UI corresponding to it
  void reloadViewedGroup(int groupId) async {
    if (ref.exists(groupViewProvider(groupId))) {
      ref.invalidate(groupViewProvider(groupId));
    }
  }

  // Takes in a list of ids of groups that were modified to check if they're currently displayed then refresh the UI corresponding to them
  void reloadViewedGroups(List<int> groupIds) async {
    for (var id in groupIds) {
      if (ref.exists(groupViewProvider(id))) {
        ref.invalidate(groupViewProvider(id));
      }
    }
  }

  // TODO: A bug that happens is when the build method is being rebuilt when a notifier such as groupsServiceProvider rebuilds, it cases an error "_groupsService has already been initialized"
  @override
  FutureOr<List<Group>> build() async {
    ref.watch(loggerProvider).w("Building groups notifier");
    var authState = ref.watch(authNotifierProvider);
    authState.when(
        data: (data) {
          if (data.isUnauthenticated) {
            throw AppError(
                message: "User is not logged in",
                stackTrace: StackTrace.current);
          }
        },
        error: (error, stackTrace) {
          throw error;
        },
        loading: () => Completer<int>().future);

    if (authState.isLoading) {
      return Completer<List<Group>>().future;
    }
    Result<List<Group>> fetchResult =
        await ref.read(groupsServiceProvider).getAllGroups();

    if (!fetchResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = fetchResult.error;
      return [];
    }

    return fetchResult.data!;
  }
}

final groupsNotifierProvider =
    AsyncNotifierProvider<GroupsNotifier, List<Group>>(GroupsNotifier.new);

// final groupProvider =
//     FutureProvider.autoDispose.family<Group, int>((ref, groupId) async {
//   final group =
//       await ref.watch(localGroupsRepositoryProvider).getGroup(groupId);

//   return group;
// });

final currentViewedGroupsProvider = Provider<List<int>>((ref) {
  return [];
});

// Group view notifier will return null if the group is not found
class GroupViewNotifier extends AutoDisposeFamilyAsyncNotifier<Group?, int> {
  void onDispose() {
    ref.read(currentViewedGroupsProvider).remove(arg);
    ref.watch(loggerProvider).w("disposing group view notifier, with id $arg");
  }

  @override
  FutureOr<Group?> build(int arg) async {
    ref.read(currentViewedGroupsProvider).add(arg);
    ref.onDispose(onDispose);
    ref.watch(loggerProvider).w("Building group view notifier, with id $arg");

    try {
      return await ref.watch(localGroupsRepositoryProvider).getGroup(arg);
    } catch (e) {
      return null;
    }
  }
}

final groupViewProvider =
    AutoDisposeAsyncNotifierProvider.family<GroupViewNotifier, Group?, int>(
        GroupViewNotifier.new);

final localGroupsRepositoryProvider = Provider<LocalGroupsRepository>((ref) {
  return LocalGroupsRepository(ref.read(localDbProvider));
});

final remoteGroupsRepositoryProvider = Provider<RemoteGroupsRepository>((ref) {
  return RemoteGroupsRepository(dio: ref.read(dioProvider));
});

final groupsServiceProvider = Provider<GroupsService>((ref) {
  // ConnectionStatus connectionStatus = ref.watch(connectionProvider);
  // bool isOnline = connectionStatus == ConnectionStatus.connected ||
  //     connectionStatus == ConnectionStatus.slow;
  // ref.read(loggerProvider).d("Constructing groups service");

  // Get auth state from notifier and assume its not error nor loading
  var authState = ref.watch(authNotifierProvider).asData!.value;
  ConnectionStatus connectionStatus = ref.watch(connectionProvider);
  var isOnline = connectionStatus == ConnectionStatus.connected ||
      connectionStatus == ConnectionStatus.slow;

  return GroupsService(
    authState: authState,
    isOnline: isOnline,
    localGroupsRepository: ref.watch(
      localGroupsRepositoryProvider,
    ),
    remoteGroupsRepository: ref.watch(remoteGroupsRepositoryProvider),
    enqueueEntry: (enqueueRequest) =>
        ref.read(outboxProvider.notifier).enqueue(enqueueRequest),
  );
});

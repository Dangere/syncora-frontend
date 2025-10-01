import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
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

  Future<void> updateGroupDetail(
      String? title, String? description, int groupId) async {
    if (title == null && description == null) return;

    ref.read(loggerProvider).d("Updating group details");
    Result<void> updateResult = await ref
        .read(groupsServiceProvider)
        .updateGroupTitle(title, description, groupId);
    ref.read(loggerProvider).d("Done updating group details");

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }

    reloadGroups();
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
  }

  Future<void> deleteTask({required int taskId, required int groupId}) async {
    Result<void> deleteResult = await ref
        .read(tasksServiceProvider)
        .deleteTask(groupId: groupId, taskId: taskId);

    if (!deleteResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = deleteResult.error;
      return;
    }
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
  }

  // Future<void> upsertGroups(List<Group> groups) async {
  //   Result<List<Group>> upsertResult =
  //       await _groupsService.upsertGroups(groups);

  //   if (!upsertResult.isSuccess) {
  //     ref.read(appErrorProvider.notifier).state = upsertResult.error;
  //     return;
  //   }

  //   state = AsyncValue.data(upsertResult.data!);
  // }

  // Future<void> fetchAndCacheRemoteGroups() async {
  //   // state = const AsyncValue.loading();
  //   Result<void> fetchResult = await _groupsService.cacheRemoteGroups();

  //   if (!fetchResult.isSuccess) {
  //     ref.read(appErrorProvider.notifier).state = fetchResult.error;
  //   }

  //   Result<List<Group>> cachedResult = await _groupsService.getAllGroups();
  //   if (!cachedResult.isSuccess) {
  //     ref.read(appErrorProvider.notifier).state = fetchResult.error;
  //   }
  //   state = AsyncValue.data(cachedResult.data!);
  // }

  Future<void> reloadGroups() async {
    Result<List<Group>> fetchResult =
        await ref.read(groupsServiceProvider).getAllGroups();

    if (!fetchResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = fetchResult.error;
    }

    state = AsyncValue.data(fetchResult.data!);
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
//     Provider.autoDispose.family<AsyncValue<Group>, int>((ref, groupId) {
//   final group = ref.watch(localGroupsRepositoryProvider).getGroup(groupId);

//   return group;
// });

final groupProvider =
    FutureProvider.autoDispose.family<Group, int>((ref, groupId) async {
  final group =
      await ref.watch(localGroupsRepositoryProvider).getGroup(groupId);

  return group;
});

final localGroupsRepositoryProvider = Provider<LocalGroupsRepository>((ref) {
  return LocalGroupsRepository(ref.read(localDbProvider));
});

// Using `autoDispose` along with `ref.read` to make sure
// Everything downstream (like GroupService, GroupRepository, etc.)
// gets rebuilt with fresh data when the parent Notifier (GroupNotifier) is re-instantiated.
// Should be careful when using ref.read instead of ref.watch because
// state change in lower dependencies won’t trigger rebuilds unless re-read manually or disposed at parent level.
// This mimics the behavior of transient dependencies in ASP.NET core.
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
    localGroupRepository: ref.watch(
      localGroupsRepositoryProvider,
    ),
    remoteGroupRepository: ref.watch(remoteGroupsRepositoryProvider),
  );
});

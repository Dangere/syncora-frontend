import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/core/data/enums/groups_filter.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_provider.dart';
import 'package:syncora_frontend/core/network/syncing/sync_state.dart';
import 'package:syncora_frontend/core/network/syncing/sync_provider.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/users/models/user.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/models/group_progress.dart';
import 'package:syncora_frontend/features/groups/repositories/local_groups_repository.dart';
import 'package:syncora_frontend/features/groups/repositories/remote_groups_repository.dart';
import 'package:syncora_frontend/features/groups/repositories/statistics_repository.dart';
import 'package:syncora_frontend/features/groups/groups_service.dart';
import 'package:syncora_frontend/features/tasks/tasks_provider.dart';
import 'package:syncora_frontend/features/users/providers/users_provider.dart';
import 'package:syncora_frontend/router.dart';

// This notifier is used to load groups for the UI
// The list updates when, local changes happen through methods, or when theres a sync payload available
// It updates as well through the outbox processor to reflect updates
// It also updates the current viewed group's notifier if its details change
// It does NOT update the tasks notifier as it works independently
class GroupsListNotifier extends AutoDisposeAsyncNotifier<List<Group>> {
  List<GroupsFilter> get filters => _filters;

  List<GroupsFilter> _filters = [GroupsFilter.inProgress];
  String? _search;

  // A bool that gets set to true when the groups list needs to be reloaded but the user is not viewing it yet
  bool _waitingToReloadGroupList = false;

  /// Gets called when the task provider modifies a task (create/modify/delete) to update the displayed list of groups
  void onTasksModification(int groupId) {
    reloadGroupsList();
  }

  // This gets called when the outbox processor updates an entity within a group or the group itself
  // It provides the group synced id
  // This gets called after ids are resolved
  void onOutboxSync(int groupId) {
    ref.read(loggerProvider).d("Groups provider: Outbox update received");

    // We dont update anything in here because it was already updated by the user action
    // However there could be a slight mismatch from returned data to the one currently
    // supposedly displayed, but this should be a minimal edge case
  }

  // This gets called when the outbox reverts an entity within a group or the group itself
  // It provides the group synced id
  // This gets called after onOutboxGroupSynced
  void onOutboxRevert(int groupId) {
    ref
        .read(loggerProvider)
        .d("Groups provider: Outbox revert received for $groupId");

    // We refresh the viewed groups and tasks to reflect the revert
    // When an entity updates within a group and is reverted
    _refreshViewedGroups([groupId]);
    // We refresh the groups list
    reloadGroupsList();
  }

  // This gets called when a group updates its temp id to a server id
  // Used to update the viewed group and tasks to use the new id (this logic was moved to be done by the outbox provider)
  // This gets called before onOutboxGroupUpdate
  void onOutboxGroupSynced(
      {required int tempId, required int serverId}) async {}

  Future<void> createGroup(
      {required String title, required String description}) async {
    // state = const AsyncValue.loading();

    Result<Group> newGroupResult =
        await ref.read(groupsServiceProvider).createGroup(title, description);

    if (!newGroupResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = newGroupResult.error;
      return;
    }

    reloadGroupsList();
  }

  Future<void> filterGroups(List<GroupsFilter> groupFilters) async {
    if (state.isLoading) {
      return;
    }
    _filters = groupFilters;
    reloadGroupsList();
  }

  Future<void> searchGroups(String? search) async {
    if (state.isLoading) {
      return;
    }

    _search = search?.trim();

    ref.read(loggerProvider).w("Groups provider: Searching for $_search");

    reloadGroupsList();
  }

  // Checks if the current user is the owner of the group, uses in-memory cache
  Future<bool> isGroupOwner(int groupId) async {
    int resolvedId = ref.read(outboxIdMapperProvider).resolveId(groupId);
    Result<bool> fetchResult = await ref
        .read(groupsServiceProvider)
        .isGroupOwner(
            groupId: resolvedId, userId: ref.read(authProvider).value!.userId!);
    if (!fetchResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = fetchResult.error;
      return false;
    }

    return fetchResult.data!;
  }

  Future<int?> getGroupsCount(List<GroupsFilter> groupFilters) async {
    Result<int> fetchResult =
        await ref.read(groupsServiceProvider).getGroupsCount(groupFilters);

    if (!fetchResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = fetchResult.error;
      return null;
    } else {
      return fetchResult.data!;
    }
  }

  Future<List<GroupProgress>> getGroupsProgress(
      bool includeAssignedTasks, int sinceDays) async {
    Result<List<GroupProgress>> fetchResult = await ref
        .read(groupsServiceProvider)
        .getGroupsProgress(includeAssignedTasks, sinceDays);

    if (!fetchResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = fetchResult.error;
      return [];
    } else {
      return fetchResult.data!;
    }
  }

  Future<GroupProgress?> getGroupsTotalProgress(
      bool includeAssignedTasks, int sinceDays) async {
    Result<GroupProgress?> fetchResult = await ref
        .read(groupsServiceProvider)
        .getGroupsTotalProgress(includeAssignedTasks, sinceDays);

    if (!fetchResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = fetchResult.error;
      return null;
    } else {
      return fetchResult.data!;
    }
  }

  void _refreshViewedGroups(List<int> ids) {
    for (int id in ids) {
      if (ref.exists(tasksProvider(id))) {
        ref.invalidate(tasksProvider(id));
      }

      if (ref.exists(groupProvider(id))) {
        ref.invalidate(groupProvider(id));
      }

      int? correlatedId = ref.read(outboxIdMapperProvider).getCorrelatedId(id);

      if (correlatedId != null) {
        if (ref.exists(tasksProvider(correlatedId))) {
          ref.invalidate(tasksProvider(correlatedId));
        }

        if (ref.exists(groupProvider(correlatedId))) {
          ref.invalidate(groupProvider(correlatedId));
        }
      }
    }
  }

  void reloadGroupsList() async {
    // Multiple calls to reload groups can happen at the same time (one for local changes and one for remote changes)
    // if (_waitingToReloadGroupList) {
    //   ref
    //       .read(loggerProvider)
    //       .d("Groups provider: Waiting to reload group list again");
    //   return;
    // }

    // if (state.isLoading) {
    //   _waitingToReloadGroupList = true;
    //   await Future.doWhile(() async {
    //     ref
    //         .read(loggerProvider)
    //         .d("Groups provider: reload group list is loading");
    //     await Future.delayed(const Duration(seconds: 3));
    //     return state.isLoading;
    //   });
    //   _waitingToReloadGroupList = false;
    // }

    // If we aren't on the home page (not viewing the groups list), we schedule a reload
    if (ref.read(routeProvider).state.name != "home") {
      ref.read(loggerProvider).d(
          "Groups provider: Tried to reload group list but not on home page");

      // _waitingToReloadGroupList = true;
      return;
    }

    ref.read(loggerProvider).d("Groups provider: Reloading groups");
    // state = const AsyncValue.loading();

    Result<List<Group>> fetchResult = await ref
        .read(groupsServiceProvider)
        .getCachedGroups(_filters, _search);

    if (!fetchResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = fetchResult.error;
      // state = AsyncValue.error(
      //     fetchResult.error!.errorObject, fetchResult.error!.stackTrace);
    } else {
      state = AsyncValue.data(fetchResult.data!);
    }
  }

  @override
  FutureOr<List<Group>> build() async {
    ref.onDispose(
      () {
        print("Groups provider: Disposing");
      },
    );
    ref.read(loggerProvider).d("Groups provider: Building");

    var authState = ref.watch(authProvider);

    // Updating the UI on group changes
    ref.listen(syncBackendProvider, (previous, next) {
      // If there is no error and the payload is not null in the next value, then we have a new payload
      if (next.error == null && !next.isLoading && next.value != null) {
        // Checking if the payload is empty or still in progress (loading)
        if (!next.value!.isAvailable || next.value!.payload!.isEmpty()) return;
        reloadGroupsList();

        // The `.modifiedGroupIds()` does not include groups with tasks that are deleted
        // Meaning when a task is deleted, the current view group wont know,
        // However it will still reflect in the tasks shown in the group by default
        // Because the tasks notifier listens to the list of deleted tasks in the sync payload and removes it
        _refreshViewedGroups(next.value!.payload!.modifiedGroupIds().toList());
      }
    });

    // Updating the UI on viewing the groups list in the home page if we had changes marked by `_waitingToReloadGroupList`
    ref.read(routeProvider.notifier).dataStream.listen(
      (event) {
        ref.read(loggerProvider).d("Groups provider: changed route to $event");

        if (event == "home") {
          // _waitingToReloadGroupList = false;
          ref.read(loggerProvider).d(
              "Groups provider: Reloading groups list on going to home page");

          reloadGroupsList();
        }
      },
    );

    // There was some weird bug, both the if (data.isAuthenticated) and if(data.isUnauthenticated) would get triggered in the same time? even if isUnauthenticated is false....

    // Okay i think i found the issue, when the user logs out and isUnauthenticated is actually set to true, it doesn't throw the error, but the moment the notifier is built again when isUnauthenticated is false, it throws the old exception from during the logout when it was true
    return authState.when(
      data: (AuthState data) async {
        if (data.isAuthenticated || data.isGuest) {
          // await Future.delayed(const Duration(seconds: 1));
          Result<List<Group>> fetchResult = await ref
              .read(groupsServiceProvider)
              .getCachedGroups(_filters, null);

          if (!fetchResult.isSuccess) {
            ref.read(appErrorProvider.notifier).state = fetchResult.error;
            return [];
          }

          return fetchResult.data!;
        } else if (data.isUnauthenticated) {
          return [];
        }
        return Completer<List<Group>>().future;
      },
      error: (error, stackTrace) {
        throw error;
      },
      loading: () {
        return Completer<List<Group>>().future;
      },
    );
  }
}

final groupsListProvider =
    AutoDisposeAsyncNotifierProvider<GroupsListNotifier, List<Group>>(
        GroupsListNotifier.new);

class GroupNotifier extends AutoDisposeFamilyAsyncNotifier<Group?, int> {
  Future<void> updateGroupDetails(
      {String? title, String? description, required int groupId}) async {
    int resolvedId = ref.read(outboxIdMapperProvider).resolveId(groupId);

    if (title == null && description == null) return;

    Result<void> updateResult = await ref
        .read(groupsServiceProvider)
        .updateGroupDetails(title, description, resolvedId);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }

    await _refreshState();
  }

  Future<void> deleteGroup(int groupId) async {
    int resolvedId = ref.read(outboxIdMapperProvider).resolveId(groupId);

    Result<void> deleteResult =
        await ref.read(groupsServiceProvider).deleteGroup(resolvedId);

    if (!deleteResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = deleteResult.error;
      return;
    }

    await _refreshState();
  }

  Future<void> leaveGroup() async {
    int resolvedId = ref.read(outboxIdMapperProvider).resolveId(arg);

    Result<void> leaveResult =
        await ref.read(groupsServiceProvider).leaveGroup(resolvedId);

    if (!leaveResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = leaveResult.error;
      return;
    }
    await _refreshState();
  }

  Future<bool> allowUserAccessToGroup(String username) async {
    int resolvedId = ref.read(outboxIdMapperProvider).resolveId(arg);

    Result updateResult = await ref
        .read(groupsServiceProvider)
        .grantAccessToGroup(
            allowAccess: true, groupId: resolvedId, usernames: [username]);

    ref.read(loggerProvider).d(updateResult);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return false;
    }

    await _refreshState();
    return true;
  }

  Future<void> allowUsersAccessToGroup(List<String> usernames) async {
    int resolvedId = ref.read(outboxIdMapperProvider).resolveId(arg);

    ref.read(loggerProvider).d("Groups provider: Adding $usernames");
    Result<void> updateResult = await ref
        .read(groupsServiceProvider)
        .grantAccessToGroup(
            allowAccess: true, groupId: resolvedId, usernames: usernames);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }
    await _refreshState();
  }

  Future<bool> removeUserAccessToGroup(String username) async {
    int resolvedId = ref.read(outboxIdMapperProvider).resolveId(arg);

    Result<void> updateResult = await ref
        .read(groupsServiceProvider)
        .grantAccessToGroup(
            allowAccess: false, groupId: resolvedId, usernames: [username]);
    ref.read(loggerProvider).d(updateResult);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return false;
    }
    await _refreshState();
    return true;
  }

  bool isGroupOwner() {
    return state.value?.ownerUserId == ref.read(authProvider).value!.userId;
  }

  Future<List<User>> getGroupMembers(bool includeOwner) async {
    int resolvedId = ref.read(outboxIdMapperProvider).resolveId(arg);

    Result<List<User>> result = await ref
        .read(usersServiceProvider)
        .getGroupMembers(resolvedId, includeOwner);
    if (!result.isSuccess) {
      ref.read(appErrorProvider.notifier).state = result.error;
      return [];
    }
    return result.data!;
  }

  Future _refreshState() async {
    ref.read(loggerProvider).d("Group provider: Refreshing state");

    // Reloading the groups list for the dashboard
    ref.read(groupsListProvider.notifier).reloadGroupsList();

    int resolvedId = ref.read(outboxIdMapperProvider).resolveId(arg);

    Result<Group?> groupResult =
        await ref.read(groupsServiceProvider).getCachedGroup(resolvedId);
    if (groupResult.isSuccess) state = AsyncData(groupResult.data);

    ref.read(appErrorProvider.notifier).state = groupResult.error;
  }

  @override
  FutureOr<Group?> build(int groupId) async {
    int resolvedId = ref.read(outboxIdMapperProvider).resolveId(arg);

    ref
        .read(loggerProvider)
        .d("Groups provider: Getting group with id $resolvedId");

    Result<Group?> groupResult =
        await ref.read(groupsServiceProvider).getCachedGroup(resolvedId);
    if (!groupResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = groupResult.error;
    }

    return groupResult.data;
  }
}

final groupProvider = AsyncNotifierProvider.autoDispose
    .family<GroupNotifier, Group?, int>(GroupNotifier.new);

final localGroupsRepositoryProvider = Provider<LocalGroupsRepository>((ref) {
  return LocalGroupsRepository(ref.read(localDbProvider));
});

final remoteGroupsRepositoryProvider = Provider<RemoteGroupsRepository>((ref) {
  return RemoteGroupsRepository(dio: ref.read(dioProvider));
});

final groupStatisticsProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository(ref.read(localDbProvider));
});

final groupsServiceProvider = Provider<GroupsService>((ref) {
  return GroupsService(
      ref.watch(localGroupsRepositoryProvider),
      ref.watch(remoteGroupsRepositoryProvider),
      ref.watch(groupStatisticsProvider),
      enqueueEntry: (enqueueRequest) =>
          ref.read(outboxProvider.notifier).enqueue(enqueueRequest),
      authStateFactory: () => ref.read(authStateProvider),
      isOnlineFactory: () => ref.read(isOnlineProvider));
});

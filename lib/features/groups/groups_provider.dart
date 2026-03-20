import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_provider.dart';
import 'package:syncora_frontend/core/network/syncing/sync_state.dart';
import 'package:syncora_frontend/core/network/syncing/sync_provider.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/models/group_progress.dart';
import 'package:syncora_frontend/features/groups/repositories/local_groups_repository.dart';
import 'package:syncora_frontend/features/groups/repositories/remote_groups_repository.dart';
import 'package:syncora_frontend/features/groups/repositories/statistics_repository.dart';
import 'package:syncora_frontend/features/groups/groups_service.dart';
import 'package:syncora_frontend/features/tasks/tasks_provider.dart';
import 'package:syncora_frontend/features/users/providers/users_provider.dart';
import 'package:syncora_frontend/router.dart';

enum GroupsFilter { inProgress, completed, shared, owned, newest, oldest }

// This notifier is used to load groups for the UI
// The list updates when, local changes happen through methods, or when theres a sync payload available
// It updates as well through the outbox processor to reflect updates
// It also updates the current viewed group's notifier if its details change
// It does NOT update the tasks notifier as it works independently
class GroupsNotifier extends AsyncNotifier<List<Group>> {
  List<GroupsFilter> get filters => _filters;

  List<GroupsFilter> _filters = [GroupsFilter.inProgress];
  String? _search;

  // A bool that gets set to true when the groups list needs to be reloaded but the user is not viewing it yet
  bool _waitingToReloadGroupList = false;

  // This gets called when the outbox processor updates an entity within a group or the group itself
  // It provides the group synced id
  // This gets called after onOutboxGroupIdUpdate
  void onOutboxSync(int groupId) {
    ref.read(loggerProvider).d("Groups provider: Outbox update received");

    // We dont update anything in here because it was already updated by the user action
    // However there could be a slight mismatch from returned data to the one currently
    // supposedly displayed, but this should be a minimal edge case
  }

  // This gets called when the outbox reverts an entity within a group or the group itself
  // It provides the group synced id
  // This gets called after onOutboxGroupIdUpdate
  void onOutboxRevert(int groupId) {
    ref.read(loggerProvider).d("Groups provider: Outbox revert received");

    // We update the viewed group to reflect the revert
    reloadViewedGroups([groupId]);

    // We update the viewed tasks to reflect the revert
    if (ref.exists(tasksProvider(groupId)))
      ref.invalidate(tasksProvider(groupId));

    // When an entity updates within a group and is reverted
    // We update the groups list
    _reloadGroupsList();
  }

  // This gets called when a group updates its temp id to a server id
  // Used to update the viewed group and tasks to use the new id
  // This gets called before onOutboxGroupUpdate
  void onOutboxGroupSynced({required int tempId, required int serverId}) async {
    // TODO: This needs work
    // ref
    //     .read(loggerProvider)
    //     .d("Groups provider: Group id updated, invalidating tasks notifiers");
    // Result<int?> serverId =
    //     await ref.read(outboxIdMapperProvider).getServerId(tempId);

    // if (!serverId.isSuccess) {
    //   ref.read(appErrorProvider.notifier).state = serverId.error;
    //   return;
    // }
    // if (serverId.data == null) {
    //   ref.read(appErrorProvider.notifier).state = ErrorMapper.map(
    //       "Groups provider: Group id not found when calling onOutboxGroupIdUpdate",
    //       null);
    //   return;
    // }

    // // When updating group id, we invalidate the tasksProvider to start listening to new id
    // if (serverId.data != null) {
    //   if (ref.exists(tasksProvider(serverId.data!)))
    //     ref.invalidate(tasksProvider(serverId.data!));
    // }

    // if (ref.exists(tasksProvider(tempId)))
    //   ref.invalidate(tasksProvider(tempId));

    // TODO: reloading all groups might be too much when one entry is updated,
    // Could be called instead when the outbox queue is done processing all entires
    _reloadGroupsList();
  }

  Future<void> createGroup(
      {required String title, required String description}) async {
    // state = const AsyncValue.loading();

    Result<Group> newGroupResult =
        await ref.read(groupsServiceProvider).createGroup(title, description);

    if (!newGroupResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = newGroupResult.error;
      return;
    }

    _reloadGroupsList();
  }

  Future<void> updateGroupDetails(
      {String? title, String? description, required int groupId}) async {
    if (title == null && description == null) return;

    ref.read(loggerProvider).d("Groups provider: Updating group details");
    Result<void> updateResult = await ref
        .read(groupsServiceProvider)
        .updateGroupDetails(title, description, groupId);
    ref.read(loggerProvider).d("Groups provider: Done updating group details");

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }

    _reloadGroupsList();
    reloadViewedGroups([groupId]);
  }

  Future<void> deleteGroup(int groupId) async {
    Result<void> deleteResult =
        await ref.read(groupsServiceProvider).deleteGroup(groupId);

    if (!deleteResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = deleteResult.error;
      return;
    }

    // These reflect local changes, the groups are onces referenced in the outbox for online changes
    _reloadGroupsList();
    reloadViewedGroups([groupId]);
  }

  Future<void> leaveGroup(int groupId) async {
    Result<void> leaveResult =
        await ref.read(groupsServiceProvider).leaveGroup(groupId);

    if (!leaveResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = leaveResult.error;
      return;
    }
    _reloadGroupsList();
    reloadViewedGroups([groupId]);
  }

  Future<bool> allowUserAccessToGroup(
      {required int groupId, required String username}) async {
    Result updateResult = await ref
        .read(groupsServiceProvider)
        .grantAccessToGroup(
            allowAccess: true, groupId: groupId, usernames: [username]);

    ref.read(loggerProvider).d(updateResult);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return false;
    }
    _reloadGroupsList();
    return true;
  }

  Future<void> allowUsersAccessToGroup(
      {required int groupId, required List<String> usernames}) async {
    ref.read(loggerProvider).d("Groups provider: Adding $usernames");
    Result<void> updateResult = await ref
        .read(groupsServiceProvider)
        .grantAccessToGroup(
            allowAccess: true, groupId: groupId, usernames: usernames);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return;
    }

    _reloadGroupsList();
  }

  Future<bool> removeUserAccessToGroup(
      {required int groupId, required String username}) async {
    Result<void> updateResult = await ref
        .read(groupsServiceProvider)
        .grantAccessToGroup(
            allowAccess: false, groupId: groupId, usernames: [username]);
    ref.read(loggerProvider).d(updateResult);

    if (!updateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = updateResult.error;
      return false;
    }
    _reloadGroupsList();
    return true;
  }

  Future<List<User>> getGroupMembers(int groupId, bool includeOwner) async {
    Result<List<User>> result = await ref
        .read(usersServiceProvider)
        .getGroupMembers(groupId, includeOwner);
    if (!result.isSuccess) {
      ref.read(appErrorProvider.notifier).state = result.error;
      return [];
    }
    return result.data!;
  }

  void _reloadGroupsList() async {
    // Multiple calls to reload groups can happen at the same time (one for local changes and one for remote changes)
    if (_waitingToReloadGroupList) return;

    if (state.isLoading) {
      _waitingToReloadGroupList = true;
      await Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 3));
        return state.isLoading;
      });
      _waitingToReloadGroupList = false;
    }

    // If we aren't on the home page (not viewing the groups list), we schedule a reload
    if (ref.read(routeProvider).state.name != "home") {
      ref.read(loggerProvider).d(
          "Groups provider: Scheduling a groups list reload on going to home page");

      _waitingToReloadGroupList = true;
      return;
    }

    ref.read(loggerProvider).d("Groups provider: Reloading groups");
    state = const AsyncValue.loading();

    Result<List<Group>> fetchResult =
        await ref.read(groupsServiceProvider).getAllGroups(_filters, _search);

    if (!fetchResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = fetchResult.error;
      state = AsyncValue.error(fetchResult.error!.errorObject,
          fetchResult.error!.stackTrace ?? StackTrace.current);
    } else {
      state = AsyncValue.data(fetchResult.data!);
    }
  }

  Future<void> filterGroups(List<GroupsFilter> groupFilters) async {
    if (state.isLoading) {
      return;
    }
    _filters = groupFilters;
    _reloadGroupsList();
  }

  Future<void> searchGroups(String? search) async {
    if (state.isLoading) {
      return;
    }

    _search = search?.trim();

    ref.read(loggerProvider).w("Groups provider: Searching for $_search");

    _reloadGroupsList();
  }

  // Checks if the current user is the owner of the group, uses in-memory cache
  bool isGroupOwner({required int groupId, required int userId}) {
    Group? group =
        state.value?.where((group) => group.id == groupId).firstOrNull;
    if (group != null) {
      return group.ownerUserId == userId;
    }
    return false;
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

  /// Updates the widgets that are displaying a group using its tempId or serverId
  void reloadViewedGroups(List<int> groupIds) async {
    ref.read(loggerProvider).d("Groups provider: Reloading group view");

    // Invalidate the group view provider for the given id, and its secondary id (tempId, or serverId)
    for (var id in groupIds) {
      if (ref.exists(groupViewProvider(id))) {
        ref.invalidate(groupViewProvider(id));
      }

      late int? secondaryId;
      // If id is negative, then it's a temp id, we get the server id if its synced
      if (id < 0) {
        Result<int?> serverIdResult =
            await ref.read(outboxIdMapperProvider).getServerId(id);

        if (serverIdResult.isSuccess) {
          secondaryId = serverIdResult.data;
        }
      }
      // If id is positive, then it's a server id, we get the temp id if its there
      else {
        Result<int?> tempId =
            await ref.read(outboxIdMapperProvider).getTempId(id);

        if (tempId.isSuccess) {
          secondaryId = tempId.data;
        }
      }
      if (secondaryId != null) {
        if (ref.exists(groupViewProvider(secondaryId))) {
          ref.invalidate(groupViewProvider(secondaryId));
        }
      }
      ;
    }
  }

  @override
  FutureOr<List<Group>> build() async {
    var authState = ref.watch(authProvider);

    // Updating the UI on group changes
    ref.listen(syncBackendProvider, (previous, next) {
      // If there is no error and the payload is not null in the next value, then we have a new payload
      if (next.error == null && !next.isLoading && next.value != null) {
        // Checking if the payload is empty or still in progress (loading)
        if (!next.value!.isAvailable || next.value!.payload!.isEmpty()) return;
        _reloadGroupsList();

        // The `.modifiedGroupIds()` does not include groups with tasks that are deleted
        // Meaning when a task is deleted, the current view group wont know,
        // However it will still reflect in the tasks shown in the group by default
        // Because the tasks notifier listens to the list of deleted tasks in the sync payload and removes it
        reloadViewedGroups(next.value!.payload!.modifiedGroupIds().toList());
      }
    });

    // Updating the UI on viewing the groups list in the home page if we had changes
    ref.read(routeProvider.notifier).dataStream.listen(
      (event) {
        if (event == "home" && _waitingToReloadGroupList) {
          _waitingToReloadGroupList = false;
          ref
              .read(loggerProvider)
              .d("Groups provider: Reloading groups list on home page");

          _reloadGroupsList();
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
              .getAllGroups(_filters, null);

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

final groupsProvider =
    AsyncNotifierProvider<GroupsNotifier, List<Group>>(GroupsNotifier.new);

final groupViewProvider =
    FutureProvider.family.autoDispose<Group?, int>((ref, id) async {
  late int resolvedId;

  // If id is negative, then it's a temp id, we get the server id if possible
  if (id < 0) {
    Result<int?> serverIdResult =
        await ref.read(outboxIdMapperProvider).getServerId(id);
    if (!serverIdResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = serverIdResult.error;
    }

    // If id doesn't have a server id, use the temp id
    if (serverIdResult.data == null) {
      resolvedId = id;
    } else {
      resolvedId = serverIdResult.data!;
    }
  } else {
    resolvedId = id;
  }
  ref
      .read(loggerProvider)
      .d("Group provider: Getting group with id $resolvedId");
  try {
    return await ref.read(localGroupsRepositoryProvider).getGroup(resolvedId);
  } catch (e, stacktrace) {
    ref.read(appErrorProvider.notifier).state = ErrorMapper.map(e, stacktrace);
    rethrow;
  }
});

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
  var authState = ref.watch(authProvider).asData!.value;
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
    groupStatisticsRepository: ref.watch(groupStatisticsProvider),
    enqueueEntry: (enqueueRequest) =>
        ref.read(outboxProvider.notifier).enqueue(enqueueRequest),
  );
});

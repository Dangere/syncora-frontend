import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/repositories/local_groups_repository.dart';
import 'package:syncora_frontend/features/groups/repositories/remote_groups_repository.dart';
import 'package:syncora_frontend/features/groups/services/groups_service.dart';

class GroupsNotifier extends AutoDisposeAsyncNotifier<List<Group>> {
  late final GroupsService _groupsService;

  Future<void> createGroup(String title, String description) async {
    // state = const AsyncValue.loading();

    Result<Group> newGroupResult =
        await _groupsService.createGroup(title, description);

    if (!newGroupResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = newGroupResult.error;
      return;
    }

    Group newGroup = newGroupResult.data!;
    // If we are trying to create a group while the state's value is null, set it to the new group
    if (!state.hasValue) {
      state = AsyncValue.data([newGroup]);
      return;
    }

    state = AsyncValue.data([...state.value!, newGroup]);
  }

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

  @override
  FutureOr<List<Group>> build() async {
    _groupsService = ref.watch(groupsServiceProvider);

    Result<List<Group>> fetchResult = await _groupsService.getAllGroups();

    if (!fetchResult.isSuccess) {
      // state = AsyncValue.error(fetchResult.error!, StackTrace.current);
      ref.read(appErrorProvider.notifier).state = fetchResult.error;
    }

    return fetchResult.data ?? [];
  }
}

final groupsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<GroupsNotifier, List<Group>>(
        GroupsNotifier.new);

final localGroupsRepositoryProvider = Provider<LocalGroupsRepository>((ref) {
  return LocalGroupsRepository(ref.read(localDbProvider));
});

// Using `autoDispose` along with `ref.read` to make sure
// Everything downstream (like GroupService, GroupRepository, etc.)
// gets rebuilt with fresh data when the parent Notifier (GroupNotifier) is re-instantiated.
// Should be careful when using ref.read instead of ref.watch because
// state change in lower dependencies won’t trigger rebuilds unless re-read manually or disposed at parent level.
// This mimics the behavior of transient dependencies in ASP.NET core.
final remoteGroupsRepositoryProvider =
    Provider.autoDispose<RemoteGroupsRepository>((ref) {
  return RemoteGroupsRepository(
      dio: ref.read(dioProvider),
      accessToken: ref.read(sessionStorageProvider).token!);
});

final groupsServiceProvider = Provider.autoDispose<GroupsService>((ref) {
  bool isGuest = ref.watch(isGuestProvider);
  ConnectionStatus connectionStatus = ref.watch(connectionProvider);
  bool isOnline = connectionStatus == ConnectionStatus.connected ||
      connectionStatus == ConnectionStatus.slow;
  return GroupsService(
    isGuest: isGuest,
    isOnline: isOnline,
    localGroupRepository: ref.read(
      localGroupsRepositoryProvider,
    ),
    remoteGroupRepository: ref.read(remoteGroupsRepositoryProvider),
  );
});

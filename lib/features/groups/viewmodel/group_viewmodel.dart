import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/groups/interfaces/group_repository_mixin.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/repository/local_group_repository.dart';
import 'package:syncora_frontend/features/groups/repository/remote_group_repository.dart';
import 'package:syncora_frontend/features/groups/services/group_service.dart';

class GroupNotifier extends AutoDisposeAsyncNotifier<List<Group>> {
  late final GroupService _groupService;

  Future<void> createGroup(String title, String description) async {
    // state = const AsyncValue.loading();

    Result<Group> newGroupResult =
        await _groupService.createGroup(title, description);

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

  @override
  FutureOr<List<Group>> build() async {
    _groupService = ref.watch(groupServiceProvider);

    Result<List<Group>> fetchResult = await _groupService.getAllGroups();

    if (!fetchResult.isSuccess) {
      // state = AsyncValue.error(fetchResult.error!, StackTrace.current);
      ref.read(appErrorProvider.notifier).state = fetchResult.error;
    }

    return fetchResult.data ?? [];
  }
}

// final groupNotifierProvider =
//     AsyncNotifierProvider<GroupNotifier, List<Group>>(
//         GroupNotifier.new);

final groupNotifierProvider =
    AutoDisposeAsyncNotifierProvider<GroupNotifier, List<Group>>(
        GroupNotifier.new);

final groupRepositoryProvider =
    Provider.autoDispose<GroupRepositoryMixin>((ref) {
  String? accessToken = ref.read(sessionStorageProvider).token;
  if (accessToken != null) {
    ref.read(loggerProvider).d('Using remote group repository');
    return RemoteGroupRepository(
        dio: ref.read(dioProvider), accessToken: accessToken);
  }

  return LocalGroupRepository();
});

final groupServiceProvider = Provider.autoDispose<GroupService>((ref) {
  return GroupService(ref.read(groupRepositoryProvider));
});

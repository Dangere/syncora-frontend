import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/groups/interfaces/group_repository_mixin.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/repository/local_group_repository.dart';
import 'package:syncora_frontend/features/groups/repository/remote_group_repository.dart';
import 'package:syncora_frontend/features/groups/services/group_service.dart';

class GroupNotifier extends AsyncNotifier<List<Group>> {
  late final GroupService _groupService;

  @override
  FutureOr<List<Group>> build() async {
    _groupService = ref.watch(groupServiceProvider);

    return await _groupService.getAllGroups();
  }
}

final groupNotifierProvider =
    AsyncNotifierProvider<GroupNotifier, List<Group>>(GroupNotifier.new);

final groupRepositoryProvider = Provider<GroupRepositoryMixin>((ref) {
  String? accessToken = ref.read(sessionStorageProvider).token;
  if (accessToken != null) {
    ref.read(loggerProvider).d('Using remote group repository');
    return RemoteGroupRepository(
        dio: ref.read(dioProvider), accessToken: accessToken);
  }

  return LocalGroupRepository();
});

final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService(ref.read(groupRepositoryProvider));
});

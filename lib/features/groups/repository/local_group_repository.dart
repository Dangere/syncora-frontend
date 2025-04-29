import 'package:syncora_frontend/features/groups/interfaces/group_repository_mixin.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';

class LocalGroupRepository implements GroupRepositoryMixin {
  @override
  Future<void> createGroup(String groupName) {
    // TODO: implement createGroup
    throw UnimplementedError();
  }

  @override
  Future<List<Group>> getAllGroups() {
    // TODO: implement getAllGroups
    return Future.value([]);
  }

  @override
  Future<void> leaveGroup(int groupId) {
    // TODO: implement leaveGroup
    throw UnimplementedError();
  }
}

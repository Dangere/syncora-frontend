import 'package:syncora_frontend/features/groups/interfaces/group_repository_mixin.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';

class LocalGroupRepository implements GroupRepositoryMixin {
  @override
  Future<Group> createGroup(String title, String description) {
    // TODO: implement createGroup
    throw UnimplementedError();
  }

  @override
  Future<List<Group>> getAllGroups() {
    // TODO: implement getAllGroups
    throw UnimplementedError();
  }

  @override
  Future<void> leaveGroup(int groupId) {
    // TODO: implement leaveGroup
    throw UnimplementedError();
  }
}

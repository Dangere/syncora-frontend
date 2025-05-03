import 'package:syncora_frontend/features/groups/models/group.dart';

abstract class GroupRepositoryMixin {
  Future<List<Group>> getAllGroups();
  Future<Group> createGroup(String groupName);
  Future<void> leaveGroup(int groupId);
}

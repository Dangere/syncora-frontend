import 'package:syncora_frontend/features/groups/models/group.dart';

abstract class GroupRepositoryMixin {
  Future<List<Group>> getAllGroups();
  Future<void> createGroup(String groupName);
  Future<void> leaveGroup(int groupId);
}

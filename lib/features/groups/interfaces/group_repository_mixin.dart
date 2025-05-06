import 'package:syncora_frontend/features/groups/models/group.dart';

abstract class GroupRepositoryMixin {
  Future<List<Group>> getAllGroups();
  Future<Group> createGroup(String title, String description);
  Future<void> leaveGroup(int groupId);
}

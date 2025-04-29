import 'package:syncora_frontend/features/groups/interfaces/group_repository_mixin.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';

class GroupService {
  final GroupRepositoryMixin _groupRepository;

  GroupService(this._groupRepository);

  Future<List<Group>> getAllGroups() async {
    return await _groupRepository.getAllGroups();
  }
}

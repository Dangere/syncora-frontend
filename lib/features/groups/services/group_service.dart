import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/groups/interfaces/group_repository_mixin.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';

class GroupService {
  final GroupRepositoryMixin _groupRepository;

  GroupService(this._groupRepository);

  Future<Result<List<Group>>> getAllGroups() async {
    try {
      List<Group> groups = await _groupRepository.getAllGroups();

      return Result.success(groups);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<Group>> createGroup(String groupName) async {
    try {
      return Result.success(await _groupRepository.createGroup(groupName));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> leaveGroup(int groupId) async {
    try {
      return Result.success(await _groupRepository.leaveGroup(groupId));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }
}

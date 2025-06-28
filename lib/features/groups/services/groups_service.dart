import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/repositories/local_groups_repository.dart';
import 'package:syncora_frontend/features/groups/repositories/remote_groups_repository.dart';

// If group is shared, user can leave and modify it when online only using remote requests
// When its local group, the user can leave and modify it when online or offline
class GroupsService {
  final LocalGroupsRepository _localGroupRepository;
  final RemoteGroupsRepository _remoteGroupRepository;

  final AuthState _authState;
  final bool _isOnline;

  GroupsService(
      {required AuthState authState,
      required bool isOnline,
      required LocalGroupsRepository localGroupRepository,
      required RemoteGroupsRepository remoteGroupRepository})
      : _localGroupRepository = localGroupRepository,
        _remoteGroupRepository = remoteGroupRepository,
        _authState = authState,
        _isOnline = isOnline;

  Future<Result<List<Group>>> getAllGroups() async {
    try {
      List<Group> groups = await _localGroupRepository.getAllGroups();
      // for (var i = 0; i < groups.length; i++) {
      //   _localGroupRepository.insertGroup(groups[i].toJson());
      // }

      return Result.success(groups);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<Group>> createGroup(String title, String description) async {
    try {
      int userId = _authState.user!.id;

      return Result.success(
          await _localGroupRepository.createGroup(title, description, userId));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  // Future<Result<void>> leaveGroup(int groupId) async {
  //   try {
  //     return Result.success(await _remoteGroupRepository.leaveGroup(groupId));
  //   } catch (e, stackTrace) {
  //     return Result.failure(ErrorMapper.map(e, stackTrace));
  //   }
  // }

  Future<Result<List<Group>>> upsertGroups(List<Group> groups) async {
    try {
      return Result.success(await _localGroupRepository.upsertGroups(groups));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }
}

import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/repositories/local_groups_repository.dart';
import 'package:syncora_frontend/features/groups/repositories/remote_groups_repository.dart';

class GroupsService {
  final LocalGroupsRepository _localGroupRepository;
  final RemoteGroupsRepository _remoteGroupRepository;

  final bool _isGuest;
  final bool _isOnline;

  GroupsService(
      {required isGuest,
      required isOnline,
      required localGroupRepository,
      required remoteGroupRepository})
      : _localGroupRepository = localGroupRepository,
        _remoteGroupRepository = remoteGroupRepository,
        _isGuest = isGuest,
        _isOnline = isOnline;

  // Future<Result<void>> cacheRemoteGroups() async {
  //   try {
  //     List<Group> groups = await _localGroupRepository.getAllGroups();
  //     for (var i = 0; i < groups.length; i++) {
  //       _localGroupRepository.upsertGroup(groups[i].toJson());
  //     }

  //     return Result.success(null);
  //   } catch (e, stackTrace) {
  //     return Result.failure(ErrorMapper.map(e, stackTrace));
  //   }
  // }

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
      return Result.success(
          await _remoteGroupRepository.createGroup(title, description));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> leaveGroup(int groupId) async {
    try {
      return Result.success(await _remoteGroupRepository.leaveGroup(groupId));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }
}

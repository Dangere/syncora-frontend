import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/models/group_dto.dart';
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

      // groups.forEach((element) {
      //   Logger().d(element.toTable());
      // });
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

      if (_isOnline) {
        await _remoteGroupRepository.createGroup(title, description);
      }

      return Result.success(
          await _localGroupRepository.createGroup(title, description, userId));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> updateGroupTitle(
      String? title, String? description, int groupId) async {
    try {
      // Logger().w(_isOnline);
      if (_isOnline) {
        print('updateGroupTitle');

        await _remoteGroupRepository.updateGroupDetails(
            title, description, groupId);

        print('done updateGroupTitle');
      }
      // await _localGroupRepository.updateGroupDetails(
      //     title, description, groupId);

      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> grantAccessToGroup(
      {required bool allowAccess,
      required String username,
      required int groupId}) async {
    try {
      if (allowAccess) {
        await _remoteGroupRepository.addUserToGroup(
            username: username, groupId: groupId);
      } else {
        await _remoteGroupRepository.removeUserFromGroup(
            username: username, groupId: groupId);
      }

      return Result.success(null);
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

  Future<Result<void>> upsertGroups(List<GroupDTO> groups) async {
    try {
      return Result.success(await _localGroupRepository.upsertGroups(groups));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> deleteGroups(List<int> groupsIds) async {
    try {
      for (var groupId in groupsIds) {
        await _localGroupRepository.deleteGroup(groupId);
      }
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }
}

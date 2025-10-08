import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_service.dart';
import 'package:syncora_frontend/core/typedef.dart';
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
  final LocalGroupsRepository _localGroupsRepository;
  final RemoteGroupsRepository _remoteGroupsRepository;
  final OutBoxEnqueueFunc<OutboxEntry, AsyncResultCallback> _enqueueEntry;

  final AuthState _authState;
  final bool _isOnline;

  GroupsService(
      {required AuthState authState,
      required bool isOnline,
      required LocalGroupsRepository localGroupsRepository,
      required RemoteGroupsRepository remoteGroupsRepository,
      required OutBoxEnqueueFunc enqueueEntry})
      : _localGroupsRepository = localGroupsRepository,
        _remoteGroupsRepository = remoteGroupsRepository,
        _authState = authState,
        _isOnline = isOnline,
        _enqueueEntry = enqueueEntry;

  Future<Result<List<Group>>> getAllGroups() async {
    try {
      List<Group> groups = await _localGroupsRepository.getAllGroups();

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
      final now = DateTime.now().toUtc();

      Group newGroup = Group(
          id: -now.millisecondsSinceEpoch,
          groupMembersIds: const [],
          tasksIds: const [],
          ownerUserId: userId,
          creationDate: now,
          title: title,
          description: description);

      Result enqueueResult = await _enqueueEntry(
        OutboxEntry.entry(
          entityTempId: newGroup.id,
          entityType: OutboxEntityType.group,
          actionType: OutboxActionType.create,
          payload: newGroup.toTable(),
        ),
        () async {
          return Result.wrap(() async {
            await _localGroupsRepository.createGroup(newGroup);
          });
        },
      );
      if (!enqueueResult.isSuccess) return Result.failure(enqueueResult.error!);

      return Result.success(newGroup);
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

        await _remoteGroupsRepository.updateGroupDetails(
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
        await _remoteGroupsRepository.addUserToGroup(
            username: username, groupId: groupId);
      } else {
        await _remoteGroupsRepository.removeUserFromGroup(
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
      return Result.success(await _localGroupsRepository.upsertGroups(groups));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> deleteGroups(List<int> groupsIds) async {
    try {
      for (var groupId in groupsIds) {
        await _localGroupsRepository.deleteGroup(groupId);
      }
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }
}

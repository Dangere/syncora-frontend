import 'package:syncora_frontend/core/network/outbox/model/enqueue_request.dart';
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
  final AsyncFunc<EnqueueRequest, Result<void>> _enqueueEntry;

  final AuthState _authState;
  final bool _isOnline;

  GroupsService(
      {required AuthState authState,
      required bool isOnline,
      required LocalGroupsRepository localGroupsRepository,
      required RemoteGroupsRepository remoteGroupsRepository,
      required AsyncFunc<EnqueueRequest, Result<void>> enqueueEntry})
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

    Result enqueueResult = await _enqueueEntry(EnqueueRequest(
      entry: OutboxEntry.entry(
        entityId: newGroup.id,
        entityType: OutboxEntityType.group,
        actionType: OutboxActionType.create,
        payload: newGroup.toTable(),
      ),
      onAfterEnqueue: () async {
        try {
          await _localGroupsRepository.createGroup(newGroup);
          return Result.success(null);
        } catch (e, stackTrace) {
          return Result.failure(ErrorMapper.map(e, stackTrace));
        }
      },
    ));
    if (!enqueueResult.isSuccess) return Result.failure(enqueueResult.error!);

    return Result.success(newGroup);
  }

  Future<Result<void>> updateGroupDetails(
      String? title, String? description, int groupId) async {
    try {
      Group group = await _localGroupsRepository.getGroup(groupId);

      Result enqueueResult = await _enqueueEntry(EnqueueRequest(
        entry: OutboxEntry.entry(
          entityId: groupId,
          entityType: OutboxEntityType.group,
          actionType: OutboxActionType.update,
          payload: {
            "title": title,
            "description": description,
            "oldTitle": group.title,
            "oldDescription": group.description
          },
        ),
        onAfterEnqueue: () async {
          try {
            await _localGroupsRepository.updateGroupDetails(
                title, description, groupId);
            return Result.success(null);
          } catch (e, stackTrace) {
            return Result.failure(ErrorMapper.map(e, stackTrace));
          }
        },
      ));
      if (!enqueueResult.isSuccess) return Result.failure(enqueueResult.error!);

      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> grantAccessToGroup(
      {required bool allowAccess,
      required String username,
      required int groupId}) async {
    if (!_isOnline) {
      return Result.failureMessage(
          "Can't grant access or revoke it when offline");
    }

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

  Future<Result<void>> leaveGroup(int groupId) async {
    if (!_isOnline) {
      return Result.failureMessage("Can't leave group when offline");
    }
    try {
      // return Result.success(await _remoteGroupRepository.leaveGroup(groupId));
      throw UnimplementedError();
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  // Deletes group by marking it as deleted which will be synced to server then fully deleted later
  // TODO: Handle this when the user is in guest mode and have no server data
  Future<Result<void>> deleteGroup(int groupId) async {
    try {
      Result enqueueResult = await _enqueueEntry(EnqueueRequest(
        entry: OutboxEntry.entry(
          entityId: groupId,
          entityType: OutboxEntityType.group,
          actionType: OutboxActionType.delete,
          payload: {},
        ),
        onAfterEnqueue: () async {
          try {
            await _localGroupsRepository.markGroupAsDeleted(groupId);
            return Result.success(null);
          } catch (e, stackTrace) {
            return Result.failure(ErrorMapper.map(e, stackTrace));
          }
        },
      ));
      if (!enqueueResult.isSuccess) return Result.failure(enqueueResult.error!);

      await _localGroupsRepository.markGroupAsDeleted(groupId);

      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> kickFromGroups(List<int> groupsIds) async {
    try {
      // TODO: show some kind of snackbar or pop up
      for (var groupId in groupsIds) {
        await _localGroupsRepository.markGroupAsDeleted(groupId);
        await _localGroupsRepository.wipeDeletedGroup(groupId);
      }

      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> upsertGroups(List<GroupDTO> groups) async {
    try {
      return Result.success(await _localGroupsRepository.upsertGroups(groups));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }
}

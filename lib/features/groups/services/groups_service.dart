import 'package:syncora_frontend/core/network/outbox/model/enqueue_request.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_payload.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/repositories/local_groups_repository.dart';
import 'package:syncora_frontend/features/groups/repositories/remote_groups_repository.dart';
import 'package:syncora_frontend/features/groups/repositories/statistics_repository.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';

// If group is shared, user can leave and modify it when online only using remote requests
// When its local group, the user can leave and modify it when online or offline
class GroupsService {
  final LocalGroupsRepository _localGroupsRepository;
  final RemoteGroupsRepository _remoteGroupsRepository;
  final StatisticsRepository _groupStatisticsRepository;
  final AsyncFunc<EnqueueRequest, Result<void>> _enqueueEntry;

  final AuthState _authState;
  final bool _isOnline;

  GroupsService(
      {required AuthState authState,
      required bool isOnline,
      required LocalGroupsRepository localGroupsRepository,
      required RemoteGroupsRepository remoteGroupsRepository,
      required StatisticsRepository groupStatisticsRepository,
      required AsyncFunc<EnqueueRequest, Result<void>> enqueueEntry})
      : _localGroupsRepository = localGroupsRepository,
        _remoteGroupsRepository = remoteGroupsRepository,
        _groupStatisticsRepository = groupStatisticsRepository,
        _authState = authState,
        _isOnline = isOnline,
        _enqueueEntry = enqueueEntry;

  Future<Result<List<Group>>> getAllGroups(
      List<GroupsFilter> filters, String? search) async {
    try {
      if (_authState.user == null) return Result.failureMessage("User is null");
      List<Group> groups = await _localGroupsRepository.getAllGroups(
          filters, _authState.user!.id, search);
      return Result.success(groups);
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
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
        payload: CreateGroupPayload(title: title, description: description),
      ),
      onAfterEnqueue: () async {
        try {
          await _localGroupsRepository.createGroup(newGroup);
          return Result.success();
        } catch (e, stackTrace) {
          return Result.failure(e, stackTrace);
        }
      },
    ));
    if (!enqueueResult.isSuccess && !enqueueResult.isCancelled) {
      return Result.failure(enqueueResult.error!,
          enqueueResult.error!.stackTrace ?? StackTrace.current);
    }

    return Result.success(newGroup);
  }

  Future<Result<void>> updateGroupDetails(
      String? title, String? description, int groupId) async {
    Group group = await _localGroupsRepository.getGroup(groupId);

    Result enqueueResult = await _enqueueEntry(EnqueueRequest(
      entry: OutboxEntry.entry(
        entityId: groupId,
        entityType: OutboxEntityType.group,
        actionType: OutboxActionType.update,
        payload: UpdateGroupPayload(
            title: title,
            description: description,
            oldTitle: group.title,
            oldDescription: group.description),
      ),
      onAfterEnqueue: () async {
        try {
          await _localGroupsRepository.updateGroupDetails(
              title, description, groupId);
          return Result.success();
        } catch (e, stackTrace) {
          return Result.failure(e, stackTrace);
        }
      },
    ));
    if (!enqueueResult.isSuccess && !enqueueResult.isCancelled)
      return enqueueResult;

    return Result.success();
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

      return Result.success();
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  Future<Result<void>> leaveGroup(int groupId) async {
    if (!_isOnline) {
      return Result.failureMessage("Can't leave group when offline");
    }
    Result enqueueResult = await _enqueueEntry(EnqueueRequest(
      entry: OutboxEntry.entry(
        entityId: groupId,
        entityType: OutboxEntityType.group,
        actionType: OutboxActionType.leave,
      ),
      onAfterEnqueue: () async {
        try {
          await _localGroupsRepository.markGroupAsDeleted(groupId);
          return Result.success();
        } catch (e, stackTrace) {
          return Result.failure(e, stackTrace);
        }
      },
    ));
    if (!enqueueResult.isSuccess && !enqueueResult.isCancelled)
      return enqueueResult;

    return Result.success();
  }

  // Deletes group by marking it as deleted which will be synced to server then fully deleted later
  // TODO: Handle this when the user is in guest mode and have no server data
  Future<Result<void>> deleteGroup(int groupId) async {
    Result enqueueResult = await _enqueueEntry(EnqueueRequest(
      entry: OutboxEntry.entry(
        entityId: groupId,
        entityType: OutboxEntityType.group,
        actionType: OutboxActionType.delete,
      ),
      onAfterEnqueue: () async {
        try {
          await _localGroupsRepository.markGroupAsDeleted(groupId);
          return Result.success();
        } catch (e, stackTrace) {
          return Result.failure(e, stackTrace);
        }
      },
    ));
    if (!enqueueResult.isSuccess && !enqueueResult.isCancelled)
      return enqueueResult;

    return Result.success();
  }

  Future<Result<int>> getGroupsCount(List<GroupsFilter> filters) async {
    try {
      if (_authState.user == null) return Result.failureMessage("User is null");

      return Result.success(await _groupStatisticsRepository.getGroupsCount(
          filters, _authState.user!.id));
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }
}

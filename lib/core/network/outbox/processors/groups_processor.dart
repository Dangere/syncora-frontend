import 'package:dio/dio.dart';
import 'package:syncora_frontend/core/network/outbox/interface/outbox_processor_interface.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/groups/models/group_dto.dart';
import 'package:syncora_frontend/features/groups/repositories/local_groups_repository.dart';
import 'package:syncora_frontend/features/groups/repositories/remote_groups_repository.dart';

class GroupsProcessor extends OutboxProcessor {
  final LocalGroupsRepository _localGroupsRepository;
  final RemoteGroupsRepository _remoteGroupsRepository;

  GroupsProcessor(
      {required LocalGroupsRepository localGroupsRepository,
      required RemoteGroupsRepository remoteGroupsRepository,
      required super.logger,
      required super.delayBeforeSyncReattempt,
      required super.idMapper})
      : _localGroupsRepository = localGroupsRepository,
        _remoteGroupsRepository = remoteGroupsRepository;

  // Takes in an outbox entry and processes it by calling the remote api and returns a result with the server id of the group or an error
  @override
  Future<Result<int>> processOutbox(OutboxEntry entry) async {
    // Making sure group exist
    if (!await _localGroupsRepository.groupExist(entry.entityId)) {
      return Result.failureMessage(
          "Outbox group processor failed to process entity ${entry.toTable()}, Group doesn't exist locally to be processed");
    }
    int? groupId;
    if (entry.actionType != OutboxActionType.create) {
      // Every time we call getServerId, we are SURE that temp id is already synced to server
      Result result = await idMapper.getServerId(entry.entityId);
      if (!result.isSuccess) return Result.failure(result.error!);
      groupId = result.data;
    }

    // This will keep processing the entry until its complete or rejected with 401
    while (true) {
      try {
        switch (entry.actionType) {
          // The create event
          case OutboxActionType.create:
            {
              GroupDTO newGroup = await _remoteGroupsRepository.createGroup(
                  entry.payload['title'], entry.payload['description']);

              await _localGroupsRepository.updateGroupId(
                  entry.entityId, newGroup.id);
              idMapper.cacheId(tempId: entry.entityId, serverId: newGroup.id);
              return Result.success(newGroup.id);
            }
          // The update event
          case OutboxActionType.update:
            {
              await _remoteGroupsRepository.updateGroupDetails(
                  entry.payload['title'],
                  entry.payload['description'],
                  groupId!);
              return Result.success(groupId);
            }
          // The delete event
          case OutboxActionType.delete:
            {
              await _remoteGroupsRepository.leaveGroup(groupId!);
              await _localGroupsRepository.wipeDeletedGroup(groupId);

              return Result.success(groupId);
            }
          default:
            return Result.success(groupId!);
        }
      } on DioException catch (e, stackTrace) {
        // If the status code is not 403, we wait and try again
        if (e.response?.statusCode != 403) {
          await Future.delayed(delayBeforeSyncReattempt);
          continue;
        } else {
          // If the status code is 403 we fail the action and revert
          logger.d(
              "Outbox group processor failed to sync entity ${entry.toTable()}, with status code: ${e.response?.statusCode}. Attempting to revert local action");

          return Result.failure(ErrorMapper.map(e, stackTrace));
        }
      } // If not an http error we return the error and fail action and revert
      catch (e, stackTrace) {
        logger.d(
            "Outbox group processor failed to sync entity ${entry.toTable()}, fatal error. Attempting to revert local action");

        return Result.failure(ErrorMapper.map(e, stackTrace));
      }
    }
  }

  // Reverting local changes if we get a 401 status code from the outbox service
  @override
  Future<Result<int>> revertProcess(OutboxEntry entry) async {
    int? groupId;
    if (entry.actionType != OutboxActionType.create) {
      // Every time we call getServerId, we are SURE that temp id is already synced to server
      Result result = await idMapper.getServerId(entry.entityId);
      if (!result.isSuccess) return Result.failure(result.error!);
      groupId = result.data;
    }

    try {
      switch (entry.actionType) {
        case OutboxActionType.create:
          // Marks group as deleted but not fully wiped off, so it can be recovered possibly
          await _localGroupsRepository.markGroupAsDeleted(entry.entityId);
          return Result.success(groupId!);
        case OutboxActionType.update:
          await _localGroupsRepository.updateGroupDetails(
              entry.payload["oldTitle"],
              entry.payload["oldDescription"],
              groupId!);
          return Result.success(groupId);

        case OutboxActionType.delete:
          await _localGroupsRepository.unmarkGroupAsDeleted(entry.entityId);
          return Result.success(groupId!);

        default:
      }

      return Result.success(groupId!);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }
}

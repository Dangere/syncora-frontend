import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:logger/web.dart';
import 'package:syncora_frontend/core/network/outbox/interface/outbox_processor_interface.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_id_mapper.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/groups/models/group_dto.dart';
import 'package:syncora_frontend/features/groups/repositories/local_groups_repository.dart';
import 'package:syncora_frontend/features/groups/repositories/remote_groups_repository.dart';

class GroupsProcessor implements OutboxProcessor {
  final LocalGroupsRepository _localGroupsRepository;
  final RemoteGroupsRepository _remoteGroupsRepository;
  final OutboxIdMapper _idMapper;
  final Logger _logger;
  final Duration _delayBeforeSyncReattempt;

  GroupsProcessor(
      {required LocalGroupsRepository localGroupsRepository,
      required RemoteGroupsRepository remoteGroupsRepository,
      required Logger logger,
      required Duration delayBeforeSyncReattempt,
      required OutboxIdMapper idMapper})
      : _idMapper = idMapper,
        _localGroupsRepository = localGroupsRepository,
        _remoteGroupsRepository = remoteGroupsRepository,
        _logger = logger,
        _delayBeforeSyncReattempt = delayBeforeSyncReattempt;

  // Takes in an outbox entry and processes it by calling the remote api and returns a result with the server id of the group or an error
  @override
  Future<Result<int>> processOutbox(OutboxEntry entry) async {
    // Making sure group exist
    if (!await _localGroupsRepository.groupExist(entry.entityId)) {
      return Result.failureMessage(
          "Outbox group processor failed to process entity ${entry.toTable()}, Group doesn't exist locally to be processed");
    }
    int? groupServerId;
    if (entry.actionType != OutboxActionType.create) {
      groupServerId = await _idMapper.getServerId(entry.entityId);
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
              _idMapper.cacheId(tempId: entry.entityId, serverId: newGroup.id);
              return Result.success(newGroup.id);
            }
          // The update event
          case OutboxActionType.update:
            {
              await _remoteGroupsRepository.updateGroupDetails(
                  entry.payload['title'],
                  entry.payload['description'],
                  groupServerId!);
              return Result.success(groupServerId);
            }
          // The delete event
          case OutboxActionType.delete:
            {
              await _remoteGroupsRepository.leaveGroup(groupServerId!);
              return Result.success(groupServerId);
            }
          default:
            return Result.success(groupServerId!);
        }
      } on DioException catch (e, stackTrace) {
        // If the status code is not 403, we wait and try again
        if (e.response?.statusCode != 403) {
          await Future.delayed(_delayBeforeSyncReattempt);
          continue;
        } else {
          // If the status code is 403 we fail the action and revert
          _logger.d(
              "Outbox group processor failed to sync entity ${entry.toTable()}, with status code: ${e.response?.statusCode}. Attempting to revert local action");

          return Result.failure(ErrorMapper.map(e, stackTrace));
        }
      } // If not an http error we return the error and fail action and revert
      catch (e, stackTrace) {
        _logger.d(
            "Outbox group processor failed to sync entity ${entry.toTable()}, fatal error. Attempting to revert local action");

        return Result.failure(ErrorMapper.map(e, stackTrace));
      }
    }
  }

  // Reverting local changes if we get a 401 status code from the outbox service
  @override
  Future<Result<void>> revertProcess(OutboxEntry entry) async {
    try {
      switch (entry.actionType) {
        case OutboxActionType.create:
          await _localGroupsRepository.deleteGroup(entry.entityId);

          break;
        case OutboxActionType.update:
          await _localGroupsRepository.updateGroupDetails(
              entry.payload["oldTitle"],
              entry.payload["oldDescription"],
              await _idMapper.getServerId(entry.entityId));

          break;
        case OutboxActionType.delete:
          // TODO: Handle this case.
          break;
        default:
      }

      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }
}

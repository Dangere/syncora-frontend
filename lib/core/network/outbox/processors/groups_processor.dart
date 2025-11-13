import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/network/outbox/exception/outbox_exception.dart';
import 'package:syncora_frontend/core/network/outbox/interface/outbox_processor_interface.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_payload.dart';
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
      required super.idMapper})
      : _localGroupsRepository = localGroupsRepository,
        _remoteGroupsRepository = remoteGroupsRepository;

  // Takes in an outbox entry and processes it by calling the remote api and returns a result with the server id of the group or an error
  // To process a group creation entry, we dont need any dependencies
  // To process a task deletion/update, we need a synced group id
  // Failing to get a dependency means we should skip processing the entry and skip reverting it

  // Creation process should ALWAYS cache the server id when successful for future processing
  @override
  Future<int> processOutbox(OutboxEntry entry) async {
    // To process a group deletion/updating we get our mandatory group id dependency
    int? groupId;
    if (entry.actionType != OutboxActionType.create) {
      Result result = await idMapper.getServerId(entry.entityId);
      if (!result.isSuccess) {
        throw OutboxDependencyFailureException(
            "Group dependency failed to get, entry: ${entry.toTable()}");
      }
      groupId = result.data;
    }
    // throw DioException.badResponse(
    //     statusCode: 403,
    //     requestOptions: RequestOptions(),
    //     response: Response(
    //         data: "unauthorized!",
    //         statusMessage: "Group already exists",
    //         requestOptions: RequestOptions(),
    //         statusCode: 403));

    switch (entry.actionType) {
      // The create event
      case OutboxActionType.create:
        {
          GroupDTO newGroup = await _remoteGroupsRepository.createGroup(
              entry.payload!.asCreateGroupPayload!.title,
              entry.payload!.asCreateGroupPayload!.description);

          await _localGroupsRepository.updateGroupId(
              entry.entityId, newGroup.id);
          idMapper.cacheId(tempId: entry.entityId, serverId: newGroup.id);
          return newGroup.id;
        }
      // The update event
      case OutboxActionType.update:
        {
          Logger().d(entry.payload!.asUpdateGroupPayload!.toJson());
          await _remoteGroupsRepository.updateGroupDetails(
              entry.payload!.asUpdateGroupPayload!.title,
              entry.payload!.asUpdateGroupPayload!.description,
              groupId!);
          return groupId;
        }
      // The delete event
      case OutboxActionType.delete:
        {
          await _remoteGroupsRepository.deleteGroup(groupId!);
          await _localGroupsRepository.wipeDeletedGroup(groupId);

          return groupId;
        }
      // The leave event
      case OutboxActionType.leave:
        {
          await _remoteGroupsRepository.leaveGroup(groupId!);
          await _localGroupsRepository.wipeDeletedGroup(groupId);

          return groupId;
        }
      default:
        return groupId!;
    }
  }

  // Reverting local changes if we get a 403 status code from the outbox service
  // This wont be called if dependencies are not met
  @override
  Future<int> revertProcess(OutboxEntry entry) async {
    int? groupId;
    if (entry.actionType != OutboxActionType.create) {
      // Every time we call getServerId, we are SURE that temp id is already synced to server
      Result result = await idMapper.getServerId(entry.entityId);
      if (!result.isSuccess) {
        throw OutboxDependencyFailureException(
            "Group dependency failed to get, entry: ${entry.toTable()}");
      }
      groupId = result.data;
    }

    switch (entry.actionType) {
      case OutboxActionType.create:
        {
          // Marks group as deleted but not fully wiped off, so it can be recovered possibly
          await _localGroupsRepository.markGroupAsDeleted(entry.entityId);
          return entry.entityId;
        }
      case OutboxActionType.update:
        {
          await _localGroupsRepository.updateGroupDetails(
              entry.payload!.asUpdateGroupPayload!.oldTitle,
              entry.payload!.asUpdateGroupPayload!.oldDescription,
              groupId!);
          return groupId;
        }

      case OutboxActionType.delete:
        {
          await _localGroupsRepository.unmarkGroupAsDeleted(entry.entityId);
        }
        return groupId!;
      case OutboxActionType.leave:
        {
          await _localGroupsRepository.unmarkGroupAsDeleted(entry.entityId);
          return groupId!;
        }

      default:
    }

    return groupId!;
  }
}

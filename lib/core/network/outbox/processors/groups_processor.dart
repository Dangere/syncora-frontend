import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:logger/web.dart';
import 'package:syncora_frontend/core/network/outbox/interface/outbox_processor_interface.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/groups/models/group_dto.dart';
import 'package:syncora_frontend/features/groups/repositories/local_groups_repository.dart';
import 'package:syncora_frontend/features/groups/repositories/remote_groups_repository.dart';

class GroupsProcessor implements OutboxProcessor {
  final LocalGroupsRepository _localGroupsRepository;
  final RemoteGroupsRepository _remoteGroupsRepository;
  final Logger _logger;
  final Duration _delayBeforeSyncReattempt;

  GroupsProcessor(
      {required LocalGroupsRepository localGroupsRepository,
      required RemoteGroupsRepository remoteGroupsRepository,
      required Logger logger,
      required Duration delayBeforeSyncReattempt})
      : _localGroupsRepository = localGroupsRepository,
        _remoteGroupsRepository = remoteGroupsRepository,
        _logger = logger,
        _delayBeforeSyncReattempt = delayBeforeSyncReattempt;
  @override

  // This will keep processing the entry until its complete or rejected with 401
  Future<Result<void>> processOutbox(OutboxEntry entry) async {
    // Making sure group exist
    if (!await _localGroupsRepository.groupExist(entry.entityId)) {
      return Result.failureMessage(
          "Outbox group processor failed to sync entity ${entry.toTable()}, Group doesn't exist locally to be processed");
    }
    while (true) {
      try {
        switch (entry.actionType) {
          case OutboxActionType.create:
            {
              GroupDTO newGroup = await _remoteGroupsRepository.createGroup(
                  entry.payload['title'], entry.payload['description']);

              await _localGroupsRepository.updateGroupId(
                  entry.entityId, newGroup.id);
              break;
            }
          case OutboxActionType.update:
            {
              await _remoteGroupsRepository.updateGroupDetails(
                  entry.payload['title'],
                  entry.payload['description'],
                  entry.entityId);

              break;
            }
          case OutboxActionType.delete:
            {
              await _remoteGroupsRepository.leaveGroup(entry.entityId);
              break;
            }
          default:
        }
        return Result.success(null);
      } on DioException catch (e, stackTrace) {
        if (e.response?.statusCode != 401) {
          _logger.d(
              "Outbox group processor failed to sync entity ${entry.toTable()}, with status code: ${e.response?.statusCode}. Attempting to redo action");

          await Future.delayed(_delayBeforeSyncReattempt);
          continue;
        }
        // Reverting local changes if we get a 401 status code
        switch (entry.actionType) {
          case OutboxActionType.create:
            {
              _logger
                  .d(await _localGroupsRepository.deleteGroup(entry.entityId));
            }
            // TODO: Handle this case.
            break;
          case OutboxActionType.update:
            // TODO: Handle this case.

            break;
          case OutboxActionType.delete:
            // TODO: Handle this case.
            break;
          default:
        }
        return Result.failure(ErrorMapper.map(e, stackTrace));
      } catch (e, stackTrace) {
        _logger.d(
            "Outbox group processor failed to sync entity ${entry.toTable()}, with error code: ${e.toString()}");
        return Result.failure(ErrorMapper.map(e, stackTrace));
      }
    }
  }
}

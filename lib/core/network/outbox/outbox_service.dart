import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/network/outbox/exception/outbox_exception.dart';
import 'package:syncora_frontend/core/network/outbox/model/enqueue_request.dart';
import 'package:syncora_frontend/core/network/outbox/interface/outbox_processor_interface.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_id_mapper.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_sorter.dart';
import 'package:syncora_frontend/core/network/outbox/repository/outbox_repository.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/result.dart';

enum OutboxErrorQueueAction {
  stopQueue,
  timeoutQueue,
  skipAndRevertEntry,
  retryEntry
}

class OutboxService {
  final OutboxRepository _outboxRepository;
  final Map<OutboxEntityType, OutboxProcessor> _processors;
  final Logger _logger;
  final Duration _rateLimitDelay;
  final Duration _timeoutDelay;

  CancellationToken? _cancelationToken;

  OutboxService(
      {required OutboxRepository outboxRepository,
      required Map<OutboxEntityType, OutboxProcessor> processors,
      required OutboxIdMapper idMapper,
      required Logger logger,
      required Duration rateLimitDelay,
      required Duration timeoutDelay})
      : _logger = logger,
        _rateLimitDelay = rateLimitDelay,
        _outboxRepository = outboxRepository,
        _processors = processors,
        _timeoutDelay = timeoutDelay;
  // Enqueue an entry to sync local data creation/update/delete with the cloud
  // It also makes sure the entry is inserted first then modify local data to avoid ghost data not syncing
  Future<Result<void>> enqueue(EnqueueRequest request) async {
    try {
      int entryId = await _outboxRepository.insertEntry(request.entry);

      if (request.onAfterEnqueue == null) return Result.success();

      // If we got local creation or updating needing to be done, we call it
      Result result = await request.onAfterEnqueue!();

      if (result.isSuccess) return Result.success();

      // If it fails, we roll back the creation of the entry
      await _outboxRepository.deleteEntry(entryId);
      return result;
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  // The processQueue function runs sequentially, one batch of entries at a time
  // this makes sure entires are properly sorted and coalesced for processing
  // It uses delegates to immediately update the UI and display errors
  // It also requires a requireSecondPass callback to tell the viewmodel that it needs a second pass

  // Processes the outbox queue and can return an error if a fetal error occurs (stops the processing of the queue)

  // TODO: One thing to consider is if the refresh token runs out and the user get a 401 response which kicks them, however in the process it will revert the changes made offline and stored in outbox.

  /// When syncing a local group to the cloud, `onGroupModified` gets called with that group's temp id
  ///
  /// `onFail` gets called with the error
  ///
  /// `requireSecondPass` gets called when the queue is done processing and possibly some new entries were undeleted so a second pass
  Future<Result<void>> processQueue(
      {required void Function({required int tempId, required int serverId})
          onEntityIdSync,
      required void Function(Exception e, StackTrace stackTrace) onFail,
      required void Function(OutboxEntry entry) onRevert,
      required void Function(OutboxEntry entry) onSync,
      required VoidCallback requireSecondPass}) async {
    _cancelationToken = CancellationToken();

    // TODO (DONE): Add some filtering here so if we are trying to add a task to a group that we delete, it should cancel out
    // dependency-aware sorting, Create group -> modify group -> create task -> modify task

    // Entries currently in the "pending" state
    var pendingEntries =
        OutboxSorter.sort(await _outboxRepository.getPendingEntries());
    // Entries that were being processed previously but got interrupted before they can reach the "complete" state
    var interruptedEntires =
        OutboxSorter.sort(await _outboxRepository.getInProcessEntries());

    // Combine the pending and interrupted entries,
    var entries = [...interruptedEntires, ...pendingEntries];

    for (final entry in entries) {
      if (_processors[entry.entityType] == null) {
        return Result.failureMessage(
            'No processor found for ${entry.entityType}');
      }

      if (_cancelationToken!.isCancelled) {
        return Result.canceled("Outbox processor: queue cancelled");
      }

      // Before we process an entity, we see if the dependencies for it are available
      // There are two types of dependencies, group dependencies and task dependencies.
      // when we are processing a group update/delete, we need a server synced group id
      // when we are processing a tasks update/delete/create, we need a server synced group id, and in the case of a update/delete, we need a server synced task id
      // Failure to get a dependency means we should skip processing the entity in need of that dependency (no reverting, just skipping entirely as the dependency itself will be unaccessible along with its children, for example failure to get a sync group id, means that group was failed to create and was already reverted (marked deleted), so anything depending on it will be unaccessible inside it for the user)

      // We process the entry, it runs a while loop until it succeeds and returns the group that was modified or returns an error that we handle here
      while (_cancelationToken!.isCancelled == false) {
        // Gets set if an entry fails and we need to revert local changes

        try {
          await _outboxRepository.markEntryInProcess(entry.id!);
          _logger.i("Processing entry $entry");
          // TODO: remove artificial delay
          // await Future.delayed(const Duration(seconds: 3));

          int processedEntityId =
              await _processors[entry.entityType]!.processToBackend(entry);

          await _outboxRepository.completeEntry(entry.id!);

          // And if its a group creation, we use the old temp group id for UI updates
          if (entry.actionType == OutboxActionType.create &&
              entry.entityType == OutboxEntityType.group) {
            // We call the onGroupIdUpdate callback to tell the UI we updated from a temp id to a server synced id
            onEntityIdSync(tempId: entry.entityId, serverId: processedEntityId);
          }

          // We call the onSync To update the UI
          // if (entry.entityType != OutboxEntityType.user)
          onSync(entry);
        } on Exception catch (e, stackTrace) {
          OutboxErrorQueueAction queueAction =
              await _handleError(e, stackTrace);

          switch (queueAction) {
            case OutboxErrorQueueAction.retryEntry:
              continue;
            // await _outboxRepository.markEntryPending(entry.id!);
            case OutboxErrorQueueAction.skipAndRevertEntry:
              {
                // Reverting
                Result<bool> revertResult =
                    (await _revertEntry(entry)).onSuccess(
                  (callPass) {
                    if (callPass) requireSecondPass();
                  },
                );

                // Failing entry
                await _outboxRepository.failEntry(entry.id!);

                if (!revertResult.isSuccess) {
                  _logger.e("Outbox debug: reverting failed");
                  break;
                }

                // callbacks
                onRevert(entry);
                onFail(e, stackTrace);
              }
              break;
            case OutboxErrorQueueAction.stopQueue:
              await _outboxRepository.markEntryPending(entry.id!);
              return Result.failure(e, stackTrace);
            case OutboxErrorQueueAction.timeoutQueue:
              {
                await _outboxRepository.markEntryPending(entry.id!);
                _logger.d('Outbox debug: Timeout error, stopping queue');
                return Result.canceled('Timeout error');
              }
          }
        }

        // Stop looping through the entry if no previous condition forced it to loop
        break;
      }
    }

    if (_cancelationToken!.isCancelled) {
      return Result.canceled("Canceling queue");
    }

    return Result.success();
  }

  Future<OutboxErrorQueueAction> _handleError(
      Exception e, StackTrace stackTrace) async {
    if (e is TimeoutException) {
      return OutboxErrorQueueAction.stopQueue;
    }

    if (e is DioException) {
      // Connection error
      if (e.type == DioExceptionType.connectionError) {
        _logger.d('Outbox debug: unable to reach server, stopping queue');
        return OutboxErrorQueueAction.stopQueue;
      }

      // Rate limit
      if (e.response?.statusCode == 429) {
        int secondsToWait = 0;

        var retryAfter = e.response!.headers['retry-after'];
        if (retryAfter != null) {
          int seconds = int.parse(e.response!.headers['retry-after']![0]);
          secondsToWait = seconds;
        }
        secondsToWait =
            retryAfter != null ? secondsToWait : _rateLimitDelay.inSeconds;
        _logger
            .d('Outbox debug: 429 error, retrying in $secondsToWait seconds');

        await Future.delayed(Duration(seconds: secondsToWait));
        _logger.d(
            'Outbox debug: Rate limit error, retrying in $secondsToWait seconds');
        return OutboxErrorQueueAction.retryEntry;
      }

      return OutboxErrorQueueAction.skipAndRevertEntry;
    }

    if (e is OutboxException) {
      return OutboxErrorQueueAction.skipAndRevertEntry;
    }

    return OutboxErrorQueueAction.stopQueue;
  }

  Future<Result<bool>> _revertEntry(OutboxEntry entry) async {
    _logger.d('Outbox debug: Reverting local for ${entry.toString()}');

    Result<int> revertResult = await Result.wrapAsync(() async =>
        await _processors[entry.entityType]!.revertLocalChange(entry));

    if (!revertResult.isSuccess) {
      return Result.failure(
          revertResult.error!, revertResult.error!.stackTrace);
    }

    // If its a deletion fail, means it could've marked other entires as ignored, so we unignore them and call for a second pass
    if (entry.actionType == OutboxActionType.delete) {
      bool entiresUnignored =
          await _outboxRepository.unignoreDependingEntries(entry.entityId);

      if (entiresUnignored) {
        return Result.success(true);
      }
    }

    return Result.success(false);
  }

  // // Gets called when the queue is running but client loses connection or the user logs out
  // void forceShutQueue() {
  //   // If _cancelationToken, it means we are not currently processing the queue

  //   if (_cancelationToken == null) {
  //     return;
  //   }
  //   _cancelationToken?.cancel();
  // }
}

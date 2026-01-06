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
import 'package:syncora_frontend/core/utils/result.dart';

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

  Future<Result<void>> processQueue(
      {required Func<int, void> onGroupModified,
      required Func<Exception, void> onFail,
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
        _cancelationToken = null;
        return Result.failureMessage(
            'No processor found for ${entry.entityType}');
      }

      if (_cancelationToken!.isCancelled) {
        _cancelationToken = null;
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
        Exception? failedEntryException;

        try {
          await _outboxRepository.markEntryInProcess(entry.id!);

          // TODO: remove artificial delay
          // await Future.delayed(const Duration(seconds: 3));

          int processResult =
              await _processors[entry.entityType]!.processToBackend(entry);

          await _outboxRepository.completeEntry(entry.id!);

          // We call the onGroupModified callback To update the UI
          onGroupModified(processResult);

          // And if its a group creation, we use the old temp group id for UI updates
          if (entry.actionType == OutboxActionType.create &&
              entry.entityType == OutboxEntityType.group) {
            // We call the onGroupModified callback To update the UI
            onGroupModified(entry.entityId);
          }
        } on OutboxDependencyFailureException catch (e) {
          await _outboxRepository.failEntry(entry.id!);
          onFail(e);
        }
        // If its a timeout error we stop the queue
        on TimeoutException {
          // The entry stays pending and we reprocessed in the next loop
          await _outboxRepository.markEntryPending(entry.id!);
          _logger.d('Outbox debug: Timeout error, stopping queue');

          _cancelationToken = null;
          return Result.canceled('Timeout error');
        }
        // If its a network error we process it
        on DioException catch (e) {
          if (e.type == DioExceptionType.connectionError) {
            await _outboxRepository.markEntryPending(entry.id!);
            _logger.d('Outbox debug: unable to reach server, stopping queue');
            _cancelationToken = null;
            return Result.canceled('Unable to reach server');
          }

          // If we get a 403 error (forbidden), we fail the entry (which will revert it)
          if (e.response?.statusCode == 403) {
            failedEntryException = e;
          }
          // If we get a 429 error (too many requests), we delay and try again
          // We extract the retry-after header and wait for that many seconds
          else if (e.response?.statusCode == 429) {
            int secondsToWait = 0;
            await _outboxRepository.markEntryPending(entry.id!);

            var retryAfter = e.response!.headers['retry-after'];
            if (retryAfter != null) {
              int seconds = int.parse(e.response!.headers['retry-after']![0]);
              secondsToWait = seconds;
            }
            secondsToWait =
                retryAfter != null ? secondsToWait : _rateLimitDelay.inSeconds;
            _logger.d(
                'Outbox debug: 429 error, retrying in $secondsToWait seconds');
            await Future.delayed(Duration(seconds: secondsToWait));

            continue;
          }
          // TODO: Other status codes could be handled here, beacuse if the error is not 403 or 429
          else {
            failedEntryException = e;
          }
        }
        // If its an exception, we fail the entry (which will revert it)
        on Exception catch (e) {
          failedEntryException = e;
        }

        // If we got a failed error, we revert the local changes
        if (failedEntryException != null) {
          onFail(failedEntryException);
          _logger.d('Outbox debug: Reverting local for ${entry.toString()}');

          Result<int> revertResult = await Result.wrapAsync(() async =>
              await _processors[entry.entityType]!.revertLocalChange(entry));

          if (!revertResult.isSuccess) {
            // If we failed to revert, we stop the entire queue and return that failed result
            _cancelationToken = null;
            return revertResult;
          }

          await _outboxRepository.failEntry(entry.id!);

          // We call the onGroupModified callback To update the UI
          onGroupModified(revertResult.data!);

          // If its a deletion fail, means it could've marked other entires as ignored, so we unignore them and call for a second pass
          if (entry.actionType == OutboxActionType.delete) {
            bool entiresUnignored = await _outboxRepository
                .unignoreDependingEntries(entry.entityId);

            if (entiresUnignored) {
              requireSecondPass();
            }
          }
        }

        // Stop looping through the entry if no previous condition forced it to loop
        break;
      }
    }

    // End of queue
    if (_cancelationToken?.isCancelled ?? false) {
      _cancelationToken = null;

      return Result.canceled("Canceling queue");
    }
    _cancelationToken = null;

    return Result.success();
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

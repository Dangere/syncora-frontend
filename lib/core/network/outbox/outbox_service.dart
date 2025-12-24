import 'dart:async';

import 'package:dio/dio.dart';
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

      if (request.onAfterEnqueue == null) return Result.success(null);

      // If we got local creation or updating needing to be done, we call it
      Result result = await request.onAfterEnqueue!();

      if (result.isSuccess) return Result.success(null);

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

  // Processes the outbox queue and can return an error if a fetal error occurs

  // TODO: One thing to consider is if the refresh token runs out and the user get a 401 response which kicks them, however in the process it will revert the changes made offline and stored in outbox.

  Future<Result<void>> processQueue(
      {required Func<int, void> onGroupModified,
      required Func<Exception, void> onFail,
      required VoidCallback requireSecondPass}) async {
    // TODO (DONE): Add some filtering here so if we are trying to add a task to a group that we delete, it should cancel out
    // dependency-aware sorting, Create group -> modify group -> create task -> modify task
    var entries =
        OutboxSorter.sort(await _outboxRepository.getPendingEntries());

    // _logger.d(
    //     "Processing ${entries.map((e) => "\n${e.toString()}\n").toList().toString()} entries");

    for (final entry in entries) {
      if (_processors[entry.entityType] == null) {
        return Result.failureMessage(
            'No processor found for ${entry.entityType}');
      }

      // Before we process an entity, we see if the dependencies for it are available
      // There are two types of dependencies, group dependencies and task dependencies.
      // when we are processing a group update/delete, we need a server synced group id
      // when we are processing a tasks update/delete/create, we need a server synced group id, and in the case of a update/delete, we need a server synced task id
      // Failure to get a dependency means we should skip processing the entity in need of that dependency (no reverting, just skipping entirely as the dependency itself will be unaccessible along with its children, for example failure to get a sync group id, means that group was failed to create and was already reverted (marked deleted), so anything depending on it will be unaccessible inside it for the user)

      // We process the entry, it runs a while loop until it succeeds and returns the group that was modified or returns an error that we handle here
      while (true) {
        // Gets set if an entry fails and we need to revert local changes
        Exception? failedError;

        try {
          await _outboxRepository.markEntryInProcess(entry.id!);
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
        } on TimeoutException {
          // The entry stays pending and processed in the next time the loop is called
          await _outboxRepository.markEntryPending(entry.id!);
          _logger.d(
              'Outbox debug: Timeout error, putting the entry as pending again');

          await Future.delayed(Duration(seconds: _timeoutDelay.inSeconds));

          continue;
        } on DioException catch (e) {
          // If we get a 403 error (forbidden), we revert the local changes and fail the entry
          if (e.response?.statusCode == 403) {
            failedError = e;
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
          } else {
            // TODO: An edge case that might happen is the error not being 401 and the loop will never end, we should handle this
            continue;
          }

          // If its a timeout error we just try again
        } on Exception catch (e) {
          failedError = e;
        }

        // If we got a failed error, we revert the local changes
        if (failedError != null) {
          onFail(failedError);
          _logger.d('Outbox debug: Reverting local for ${entry.toString()}');

          Result<int> revertResult = await Result.wrapAsync(() async =>
              await _processors[entry.entityType]!.revertLocalChange(entry));

          if (!revertResult.isSuccess) {
            return revertResult;
          }

          await _outboxRepository.failEntry(entry.id!);

          // We call the onGroupModified callback To update the UI
          onGroupModified(revertResult.data!);

          // If its a deletion fail, means it could've marked other entires as ignored, so we unignore them and call for a second pass
          if (entry.actionType == OutboxActionType.delete) {
            await _outboxRepository.unignoreDependingEntries(entry.entityId);
            requireSecondPass();
          }
          break;
        }

        break;
      }
    }
    return Result.success(null);
  }
}

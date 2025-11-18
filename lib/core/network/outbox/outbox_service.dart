import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/network/outbox/exception/outbox_exception.dart';
import 'package:syncora_frontend/core/network/outbox/model/enqueue_request.dart';
import 'package:syncora_frontend/core/network/outbox/interface/outbox_processor_interface.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/model/queue_processor_response.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_id_mapper.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_sorter.dart';
import 'package:syncora_frontend/core/network/outbox/repository/outbox_repository.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';

class OutboxService {
  final OutboxRepository _outboxRepository;
  final Map<OutboxEntityType, OutboxProcessor> _processors;
  final Logger _logger;
  final Duration _rateLimitDelay;

  OutboxService(
      {required OutboxRepository outboxRepository,
      required Map<OutboxEntityType, OutboxProcessor> processors,
      required OutboxIdMapper idMapper,
      required Logger logger,
      required Duration rateLimitDelay})
      : _logger = logger,
        _rateLimitDelay = rateLimitDelay,
        _outboxRepository = outboxRepository,
        _processors = processors;

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
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  // The processQueue function runs sequentially, one batch of entries at a time
  // this makes sure entires are properly sorted and coalesced for processing
  // Processes the outbox queue and returns a list of all modified groups for UI updates
  // TODO: One thing to consider is if the refresh token runs out and the user get a 401 response which kicks them, however in the process it will revert the changes made offline and stored in outbox.
  Future<Result<QueueProcessorResponse>> processQueue() async {
    HashSet<int> modifiedGroupIds = HashSet<int>();
    List<Exception> errors = [];
    // TODO: Add some filtering here so if we are trying to add a task to a group that we delete, it should cancel out
    // dependency-aware sorting, Create group -> modify group -> create task -> modify task
    var entries =
        OutboxSorter.sort(await _outboxRepository.getPendingEntries());

    for (final entry in entries) {
      if (_processors[entry.entityType] == null) {
        return Result.failure(AppError(
            message: 'No processor found for ${entry.entityType}',
            stackTrace: StackTrace.current));
      }

      // Before we process an entity, we see if the dependencies for it are available
      // There are two types of dependencies, group dependencies and task dependencies.
      // when we are processing a group update/delete, we need a server synced group id
      // when we are processing a tasks update/delete/create, we need a server synced group id, and in the case of a update/delete, we need a server synced task id
      // Failure to get a dependency means we should skip processing the entity in need of that dependency (no reverting, just skipping entirely as the dependency itself will be unaccessible along with its children, for example failure to get a sync group id, means that group was failed to create and was already reverted (marked deleted), so anything depending on it will be unaccessible inside it for the user)

      // We process the entry, it runs a while loop until it succeeds and returns the group that was modified or returns an error that we handle here
      while (true) {
        try {
          _outboxRepository.markEntryInProcess(entry.id!);
          int processResult =
              await _processors[entry.entityType]!.processToBackend(entry);

          _outboxRepository.completeEntry(entry.id!);

          // We store the group id
          modifiedGroupIds.add(processResult);

          // And if its a group creation, we we store the old temp group id as a modified group for UI updates
          if (entry.actionType == OutboxActionType.create &&
              entry.entityType == OutboxEntityType.group) {
            modifiedGroupIds.add(entry.entityId);
          }
        } on OutboxDependencyFailureException catch (e) {
          _outboxRepository.failEntry(entry.id!);
          errors.add(e);
          break;
        } on DioException catch (e) {
          // If we get a 403 error (forbidden), we try to revert the changes and fail the action
          if (e.response?.statusCode == 403) {
            _outboxRepository.failEntry(entry.id!);
            Result<int> revertResult = await Result.wrapAsync(() async =>
                await _processors[entry.entityType]!.revertLocalChange(entry));

            // If ANY revert fails, we break out of the process loop and return the error
            if (!revertResult.isSuccess) {
              return Result.failure(revertResult.error!);
            }

            errors.add(e);
            modifiedGroupIds.add(revertResult.data!);
          }
          // If we get a 429 error (too many requests), we delay and try again
          // We extract the retry-after header and wait for that many seconds
          else if (e.response?.statusCode == 429) {
            int secondsToWait = 0;
            _outboxRepository.markEntryPending(entry.id!);

            var retryAfter = e.response!.headers['retry-after'];
            if (retryAfter != null) {
              int seconds = int.parse(e.response!.headers['retry-after']![0]);
              secondsToWait = seconds;
            }
            secondsToWait =
                retryAfter != null ? secondsToWait : _rateLimitDelay.inSeconds;
            _logger.d('429 error, retrying in $secondsToWait seconds');
            await Future.delayed(Duration(seconds: secondsToWait));

            continue;
          } else {
            // TODO: An edge case that might happen is the error not being 403 and the loop will never end, we should handle this
            continue;
          }
        } on Exception catch (e) {
          Result<int> revertResult = await Result.wrapAsync(() async =>
              await _processors[entry.entityType]!.revertLocalChange(entry));

          if (!revertResult.isSuccess) {
            return Result.failure(revertResult.error!);
          }
          modifiedGroupIds.add(revertResult.data!);
          _outboxRepository.failEntry(entry.id!);
          errors.add(e);
        }
        break;
      }
    }
    return Result.success(QueueProcessorResponse(modifiedGroupIds, errors));
  }
}

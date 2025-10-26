import 'dart:collection';

import 'package:dio/dio.dart';
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
  OutboxService(
      {required OutboxRepository outboxRepository,
      required Map<OutboxEntityType, OutboxProcessor> processors,
      required OutboxIdMapper idMapper})
      : _outboxRepository = outboxRepository,
        _processors = processors;

  // Enqueue an entry to sync local data creation/update/delete with the cloud
  // It also makes sure the entry is inserted first then modify local data to avoid ghost data not syncing
  Future<Result<void>> enqueue(EnqueueRequest request) async {
    try {
      // TODO: Add some filtering here so if we are trying to add a task to a group that we delete, it should cancel out
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

  // Processes the outbox queue and returns a list of all modified groups for UI updates
  Future<Result<QueueProcessorResponse>> processQueue() async {
    HashSet<int> modifiedGroupIds = HashSet<int>();
    List<AppError> errors = [];

    // dependency-aware sorting, Create group -> modify group -> create task -> modify task
    var entries =
        OutboxSorter.sort(await _outboxRepository.getPendingEntries());

    for (final entry in entries) {
      if (_processors[entry.entityType] == null) {
        return Result.failure(AppError(
            message: 'No processor found for ${entry.entityType}',
            stackTrace: StackTrace.current));
      }

      // TODO: One thing to consider is if the refresh token runs out and the user get a 401 response which kicks them, however in the process it will revert the changes made offline and stored in outbox.

      // We process the entry, it runs a while loop until it succeeds and returns the group that was modified or returns an 403 error or generic error
      Result<int> processResult =
          await _processors[entry.entityType]!.processOutbox(entry);

      if (processResult.isSuccess) {
        _outboxRepository.completeEntry(entry.id!);

        // We store the group id
        modifiedGroupIds.add(processResult.data!);

        // And if its a group creation, we we store the old temp group id as a modified group for UI updates
        if (entry.actionType == OutboxActionType.create &&
            entry.entityType == OutboxEntityType.group) {
          modifiedGroupIds.add(entry.entityId);
        }
      } else {
        // If the processes fails because of a 403 error or generic error we revert the local changes
        Result<int> revertResult =
            await _processors[entry.entityType]!.revertProcess(entry);

        // If we failed to revert the changes, we dont mark the entry as failed yet so its processed in the future
        if (!revertResult.isSuccess) {
          errors.add(revertResult.error!);

          return Result.failure(revertResult.error!);
        }

        modifiedGroupIds.add(revertResult.data!);
        _outboxRepository.failEntry(entry.id!);

        // We store the fail response error
        errors.add(processResult.error!);
      }
    }
    return Result.success(QueueProcessorResponse(modifiedGroupIds, errors));
  }
}

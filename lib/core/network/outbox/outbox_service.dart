import 'package:syncora_frontend/core/network/outbox/interface/outbox_processor_interface.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_sorter.dart';
import 'package:syncora_frontend/core/network/outbox/repository/outbox_repository.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';

class OutboxService {
  final OutboxRepository _outboxRepository;
  final Map<OutboxEntityType, OutboxProcessor> _processors;
  OutboxService({required outboxRepository, required processors})
      : _outboxRepository = outboxRepository,
        _processors = processors;

  // Enqueue an entry to sync local data creation/update/delete with the cloud
  // It also makes sure the entry is inserted first then modify local data to avoid ghost data not syncing
  Future<Result<void>> enqueue(
      OutboxEntry entry, AsyncResultCallback<void>? onAfterEnqueue) async {
    try {
      // TODO: Add some filtering here so if we are trying to add a task to a group that we delete, it should cancel out
      await _outboxRepository.insertEntry(entry);

      if (onAfterEnqueue == null) return Result.success(null);

      // If we got local creation or updating needing to be done, we call it
      Result result = await onAfterEnqueue();

      if (result.isSuccess) return Result.success(null);

      // If it fails, we roll back the creation of the entry
      await _outboxRepository.deleteEntry(entry.id!);
      return result;
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> processQueue() async {
    // dependency-aware sorting, Create group -> modify group -> create task -> modify task
    var entries =
        OutboxSorter.sort(await _outboxRepository.getPendingEntries());

    for (final entry in entries) {
      if (_processors[entry.entityType] == null) {
        return Result.failure(AppError(
            message: 'No processor found for ${entry.entityType}',
            stackTrace: StackTrace.current));
      }

      Result processResult =
          await _processors[entry.entityType]!.processOutbox(entry);

      if (!processResult.isSuccess) {
        _outboxRepository.failEntry(entry.id!);
        return Result.failure(processResult.error!);
      } else {
        _outboxRepository.completeEntry(entry.id!);
      }
    }
    return Result.success(null);
  }
}

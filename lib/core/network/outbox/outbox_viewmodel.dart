import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/repository/outbox_repository.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';

// Im testing something different in this notifier unlike other notifiers,
// This notifier doesn't require a service to function, instead it uses the repo directly
// Because honestly im realizing most of my services classes are acting just like an error wrapper
// But riverpod by default wraps errors in the notifier
class OutboxNotifier extends AsyncNotifier<int> {
  Future<void> enqueue(OutboxEntry entry) async {
    try {
      // TODO: Add some filtering here so if we are trying to remove a task when its it was added it should cancel each other out
      await ref.read(outboxRepositoryProvider).insertEntry(entry);
    } catch (e) {
      AppError error = ErrorMapper.map(e, StackTrace.current);
      ref.read(appErrorProvider.notifier).state = error;
      state = AsyncValue.error(error.message, error.stackTrace!);
    }

    await processQueue();
  }

  Future<void> processQueue() async {
    final entries =
        await ref.read(outboxRepositoryProvider).getPendingEntries();

    for (final entry in entries) {
      ref.read(loggerProvider).w(entry.toTable());
      // try {
      //   await _sendToServer(entry); // Dio call
      //   await repo.markAsCompleted(entry.id);
      //   _applySuccess(
      //       entry); // e.g. update tempId→serverId, hard delete if needed
      // } catch (e) {
      //   await repo.markAsFailed(entry.id);
      //   _revertLocal(entry); // undo local optimistic change if needed
      // }
    }
  }

  // Sends action to API call, We assume the action was already executed locally
  // Future<void> sendApiAction(OutboxEntry entry) {
  //   if (entry.entityType == OutboxEntityType.task) {
  //     switch (entry.actionType) {
  //       case OutBoxActionType.create:
  //         break;
  //       case OutBoxActionType.delete:
  //         break;
  //       case OutBoxActionType.mark:
  //         break;
  //       case OutBoxActionType.update:
  //         break;
  //       default:
  //     }
  //   } else if (entry.entityType == OutboxEntityType.group) {
  //     switch (entry.actionType) {
  //       case OutBoxActionType.create:
  //         break;
  //       case OutBoxActionType.delete:
  //         break;
  //       case OutBoxActionType.mark:
  //         break;
  //       case OutBoxActionType.update:
  //         break;
  //       default:
  //     }
  //   }
  // }

  // // Reverts action locally on API request fail
  // Future<void> revertAction(OutboxEntry entry) {
  //   if (entry.entityType == OutboxEntityType.task) {
  //     switch (entry.actionType) {
  //       case OutBoxActionType.create:
  //         break;
  //       case OutBoxActionType.delete:
  //         break;
  //       case OutBoxActionType.mark:
  //         break;
  //       case OutBoxActionType.update:
  //         break;
  //       default:
  //     }
  //   } else if (entry.entityType == OutboxEntityType.group) {
  //     switch (entry.actionType) {
  //       case OutBoxActionType.create:
  //         break;
  //       case OutBoxActionType.delete:
  //         break;
  //       case OutBoxActionType.mark:
  //         break;
  //       case OutBoxActionType.update:
  //         break;
  //       default:
  //     }
  //   }
  // }

  @override
  int build() {
    return 0;
  }
}

final outboxProvider =
    AsyncNotifierProvider<OutboxNotifier, int>(OutboxNotifier.new);

final outboxRepositoryProvider = Provider<OutboxRepository>((ref) {
  return OutboxRepository(databaseManager: ref.watch(localDbProvider));
});

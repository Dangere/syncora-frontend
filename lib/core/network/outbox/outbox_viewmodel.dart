import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_service.dart';
import 'package:syncora_frontend/core/network/outbox/processors/groups_processor.dart';
import 'package:syncora_frontend/core/network/outbox/processors/tasks_processor.dart';
import 'package:syncora_frontend/core/network/outbox/repository/outbox_repository.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';
import 'package:syncora_frontend/features/tasks/viewmodel/tasks_providers.dart';

final outboxServiceProvider = Provider<OutboxService>((ref) {
  return OutboxService(
      outboxRepository: ref.watch(outboxRepositoryProvider),
      processors: {
        OutboxEntityType.task: ref.watch(tasksProcessorProvider),
        OutboxEntityType.group: ref.watch(groupProcessorProvider),
      });
});

class OutboxNotifier extends AsyncNotifier<OutboxStatus> {
  // Calls the enqueue method and processes the queue list and updates UI accordingly
  Future<Result<void>> enqueue(
      OutboxEntry entry, AsyncResultCallback<void>? onAfterEnqueue) async {
    state = const AsyncValue.loading();
    Result<void> result =
        await ref.read(outboxServiceProvider).enqueue(entry, onAfterEnqueue);

    if (result.isSuccess) {
      processQueue();
      state = const AsyncValue.data(OutboxStatus.complete);
    } else {
      state = AsyncValue.error(
          result.error!, result.error!.stackTrace ?? StackTrace.current);
    }
    return result;
  }

  Future<Result<void>> processQueue() async {
    if (ref.read(connectionProvider) == ConnectionStatus.disconnected) {
      return Result.failureMessage("Cant process outbox queue when offline");
    }

    ref.read(loggerProvider).i("Processing Outbox Queue!");
    Result<void> result = await ref.read(outboxServiceProvider).processQueue();

    if (!result.isSuccess) {
      ref.read(appErrorProvider.notifier).state = result.error;
    }
    if (ref.exists(groupsNotifierProvider)) {
      ref.read(groupsNotifierProvider.notifier).reloadGroups();
    }
    return result;
  }

  @override
  FutureOr<OutboxStatus> build() async {
    Result result = await processQueue();

    if (result.isSuccess) {
      return OutboxStatus.complete;
    } else {
      throw result.error!;
    }
  }
}

final outboxProvider =
    AsyncNotifierProvider<OutboxNotifier, OutboxStatus>(OutboxNotifier.new);

final outboxRepositoryProvider = Provider<OutboxRepository>((ref) {
  return OutboxRepository(databaseManager: ref.watch(localDbProvider));
});

final tasksProcessorProvider = Provider<TasksProcessor>((ref) {
  return TasksProcessor(
      localTasksRepository: ref.watch(localTasksRepositoryProvider),
      remoteTasksRepository: ref.watch(remoteTasksRepositoryProvider));
});

final groupProcessorProvider = Provider<GroupsProcessor>((ref) {
  return GroupsProcessor(
      localGroupsRepository: ref.watch(localGroupsRepositoryProvider),
      remoteGroupsRepository: ref.watch(remoteGroupsRepositoryProvider),
      logger: ref.read(loggerProvider),
      delayBeforeSyncReattempt: const Duration(milliseconds: 200));
});

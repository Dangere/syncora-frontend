import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/core/network/outbox/model/enqueue_request.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/model/queue_processor_response.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_id_mapper.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_service.dart';
import 'package:syncora_frontend/core/network/outbox/processors/groups_processor.dart';
import 'package:syncora_frontend/core/network/outbox/processors/tasks_processor.dart';
import 'package:syncora_frontend/core/network/outbox/repository/outbox_repository.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';
import 'package:syncora_frontend/features/tasks/viewmodel/tasks_providers.dart';

class OutboxNotifier extends AsyncNotifier<OutboxStatus> {
  // Calls the enqueue method and processes the queue list and updates UI accordingly
  Future<Result<void>> enqueue(EnqueueRequest request) async {
    state = const AsyncValue.loading();
    Result<void> result =
        await ref.read(outboxServiceProvider).enqueue(request);

    if (result.isSuccess) {
      processQueue();
      state = const AsyncValue.data(OutboxStatus.complete);
    } else {
      state = AsyncValue.error(
          result.error!, result.error!.stackTrace ?? StackTrace.current);
    }
    return result;
  }

  // Processes the outbox queue and updates the UI with new data
  Future<Result<void>> processQueue() async {
    if (ref.read(connectionProvider) == ConnectionStatus.disconnected) {
      return Result.failureMessage("Cant process outbox queue when offline");
    }

    await Future.delayed(Duration(seconds: 5));

    ref.read(loggerProvider).i("Processing Outbox Queue!");
    Result<QueueProcessorResponse> response =
        await ref.read(outboxServiceProvider).processQueue();

    if (!response.isSuccess) {
      ref.read(appErrorProvider.notifier).state = response.error;
    }

    // Updating the UI for groups list
    if (ref.exists(groupsNotifierProvider)) {
      ref.read(groupsNotifierProvider.notifier).reloadGroups();
      // Updating the UI for current displayed groups, including with real ids and temp ones
      ref
          .read(groupsNotifierProvider.notifier)
          .reloadViewedGroups(response.data!.modifiedGroupIds.toList());
    }

    // Displaying errors
    response.data!.errors.forEach((error) async {
      ref.read(appErrorProvider.notifier).state = error;
      await Future.delayed(const Duration(seconds: 2));
    });

    ref.read(loggerProvider).i("Done processing Outbox Queue!");

    return response;
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

final outboxServiceProvider = Provider<OutboxService>((ref) {
  return OutboxService(
      outboxRepository: ref.watch(outboxRepositoryProvider),
      processors: {
        OutboxEntityType.task: ref.watch(tasksProcessorProvider),
        OutboxEntityType.group: ref.watch(groupProcessorProvider),
      },
      idMapper: ref.watch(outboxIdMapperProvider));
});

final outboxRepositoryProvider = Provider<OutboxRepository>((ref) {
  return OutboxRepository(databaseManager: ref.watch(localDbProvider));
});

final outboxIdMapperProvider = Provider<OutboxIdMapper>((ref) {
  return OutboxIdMapper(ref.watch(outboxRepositoryProvider));
});

final tasksProcessorProvider = Provider<TasksProcessor>((ref) {
  return TasksProcessor(
      delayBeforeSyncReattempt: const Duration(milliseconds: 1000),
      localTasksRepository: ref.watch(localTasksRepositoryProvider),
      remoteTasksRepository: ref.watch(remoteTasksRepositoryProvider),
      logger: ref.read(loggerProvider),
      idMapper: ref.watch(outboxIdMapperProvider));
});

final groupProcessorProvider = Provider<GroupsProcessor>((ref) {
  return GroupsProcessor(
      delayBeforeSyncReattempt: const Duration(milliseconds: 1000),
      localGroupsRepository: ref.watch(localGroupsRepositoryProvider),
      remoteGroupsRepository: ref.watch(remoteGroupsRepositoryProvider),
      logger: ref.read(loggerProvider),
      idMapper: ref.watch(outboxIdMapperProvider));
});

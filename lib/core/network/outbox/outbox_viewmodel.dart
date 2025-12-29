import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/core/network/outbox/model/enqueue_request.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_id_mapper.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_service.dart';
import 'package:syncora_frontend/core/network/outbox/processors/groups_processor.dart';
import 'package:syncora_frontend/core/network/outbox/processors/tasks_processor.dart';
import 'package:syncora_frontend/core/network/outbox/repository/outbox_repository.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';
import 'package:syncora_frontend/features/tasks/viewmodel/tasks_providers.dart';

class OutboxNotifier extends AsyncNotifier<OutboxStatus> {
  bool _isProcessing = false;
  bool _isAwaiting = false;

  // Calls the enqueue method and processes the queue list and updates UI accordingly
  Future<Result<void>> enqueue(EnqueueRequest request) async {
    state = const AsyncValue.loading();
    Result<void> result =
        await ref.read(outboxServiceProvider).enqueue(request);

    if (!result.isSuccess) {
      state = AsyncValue.error(
          result.error!, result.error!.stackTrace ?? StackTrace.current);
      return result;
    }

    if (ref.read(connectionProvider) == ConnectionStatus.disconnected) {
      state = const AsyncValue.data(OutboxStatus.pending);
      return Result.canceled("Cant process outbox queue when offline");
    }

    processQueue();
    state = const AsyncValue.data(OutboxStatus.inProcess);

    return result;
  }

  // Processes the outbox queue and updates the UI with new data
  // This gets called whenever the connection status changes or when the outbox queue is updated
  // TODO: Show an indication to the user that shows if the queue is being processed or paused or faced an error

  // TODO: A behavior i noticed is that when processing a list of entries at once, the actions will revert on failing but it wont update the UI or show errors until the entire list is processed, which is a bit confusing for the user,
  Future<Result<void>> processQueue() async {
    // If we are trying to process the queue while we are already processing it, we mark it as awaiting
    if (_isProcessing) {
      if (!_isAwaiting) {
        _isAwaiting = true;
      }

      return Result.success();
    }
    _isProcessing = true;
    // await Future.delayed(Duration(seconds: 5));

    state = const AsyncValue.loading();

    // ref.read(loggerProvider).i("Processing Outbox Queue!");
    Result<void> response = await ref.read(outboxServiceProvider).processQueue(
      onFail: (error) {
        ref.read(appErrorProvider.notifier).state = ErrorMapper.map(error);
      },
      onGroupModified: (groupId) {
        // TODO: This is being called on each group update to reflect the changes on the UI but relaoding the entire groups each time is a bit expensive...
        ref.read(groupsNotifierProvider.notifier).reloadGroups();
        ref.read(groupsNotifierProvider.notifier).reloadViewedGroup(groupId);
      },
      requireSecondPass: () {
        ref
            .read(loggerProvider)
            .w("Outbox Queue: We are calling for a second pass!");
        _isAwaiting = true;
      },
    );

    if (!response.isSuccess) {
      ref.read(appErrorProvider.notifier).state = response.error;
      state = AsyncValue.error(response.error!.message,
          response.error!.stackTrace ?? StackTrace.current);
    }

    // ref.read(loggerProvider).i("Done processing Outbox Queue!");

    if (response.isSuccess) {
      state = const AsyncValue.data(OutboxStatus.complete);
    }

    _isProcessing = false;
    // If we have entires waiting to be processed after this, process them
    if (_isAwaiting) {
      _isAwaiting = false;
      ref.read(loggerProvider).i(
          "Outbox Queue: Second pass was required, proceeding with second pass!");
      processQueue();
    }
    return response;
  }

  void
      handelInProcess() {} // TODO: Handle inProcess entires that were interrupted by a forceful disconnect

  void onDispose() {
    _isProcessing = false;
    _isAwaiting = false;
  }

  @override
  FutureOr<OutboxStatus> build() async {
    ref.onDispose(onDispose);
    ref.listen(connectionProvider, (previous, next) async {
      if (next == ConnectionStatus.connected || next == ConnectionStatus.slow) {
        _isProcessing = false;
        _isAwaiting = false;
        // ref
        //     .read(loggerProvider)
        //     .i("Processing Outbox Queue on connection change!");
        await processQueue();
      }
    });
    _isProcessing = false;
    _isAwaiting = false;
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
      rateLimitDelay: Duration(seconds: 10),
      timeoutDelay: Duration(seconds: 10),
      logger: ref.read(loggerProvider),
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
      localTasksRepository: ref.watch(localTasksRepositoryProvider),
      remoteTasksRepository: ref.watch(remoteTasksRepositoryProvider),
      logger: ref.read(loggerProvider),
      idMapper: ref.watch(outboxIdMapperProvider));
});

final groupProcessorProvider = Provider<GroupsProcessor>((ref) {
  return GroupsProcessor(
      localGroupsRepository: ref.watch(localGroupsRepositoryProvider),
      remoteGroupsRepository: ref.watch(remoteGroupsRepositoryProvider),
      logger: ref.read(loggerProvider),
      idMapper: ref.watch(outboxIdMapperProvider));
});

import 'package:syncora_frontend/core/network/outbox/interface/outbox_processor_interface.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/tasks/repositories/local_tasks_repository.dart';
import 'package:syncora_frontend/features/tasks/repositories/remote_tasks_repository.dart';

class TasksProcessor implements OutboxProcessor {
  final LocalTasksRepository _localTasksRepository;
  final RemoteTasksRepository _remoteTasksRepository;

  TasksProcessor(
      {required localTasksRepository, required remoteTasksRepository})
      : _localTasksRepository = localTasksRepository,
        _remoteTasksRepository = remoteTasksRepository;
  @override
  Future<Result<int>> processOutbox(OutboxEntry entry) {
    // int groupId = entry.payload["groupId"];

    // TODO: implement processOutbox
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> revertProcess(OutboxEntry entry) {
    // TODO: implement revertProcess
    throw UnimplementedError();
  }
}

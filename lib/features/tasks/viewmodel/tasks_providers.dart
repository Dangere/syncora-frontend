import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/features/tasks/repositories/local_tasks_repository.dart';
import 'package:syncora_frontend/features/tasks/repositories/remote_tasks_repository.dart';
import 'package:syncora_frontend/features/tasks/services/tasks_service.dart';

final localTasksRepositoryProvider = Provider<LocalTasksRepository>((ref) {
  return LocalTasksRepository(ref.watch(localDbProvider));
});

final remoteTasksRepositoryProvider = Provider<RemoteTasksRepository>((ref) {
  return RemoteTasksRepository(dio: ref.watch(dioProvider));
});

final tasksServiceProvider = Provider<TasksService>((ref) {
  return TasksService(
      localTasksRepository: ref.watch(localTasksRepositoryProvider),
      remoteTasksRepository: ref.watch(remoteTasksRepositoryProvider));
});

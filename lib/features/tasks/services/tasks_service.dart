import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';
import 'package:syncora_frontend/features/tasks/repositories/local_tasks_repository.dart';
import 'package:syncora_frontend/features/tasks/repositories/remote_tasks_repository.dart';

class TasksService {
  final LocalTasksRepository localTasksRepository;
  final RemoteTasksRepository remoteTasksRepository;

  TasksService(
      {required this.localTasksRepository,
      required this.remoteTasksRepository});

  Future<Result<List<Task>>> getTasksForGroup(int groupId) async {
    try {
      List<Task> tasks = await localTasksRepository.getTasksForGroup(groupId);
      return Result.success(tasks);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> upsertTasks(List<Task> tasks) async {
    try {
      return Result.success(await localTasksRepository.upsertTasks(tasks));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> deleteTask(
      {required int taskId, required int groupId}) async {
    try {
      return Result.success(await remoteTasksRepository.deleteTask(
          groupId: groupId, taskId: taskId));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> updateTask(
      {required int taskId,
      required int groupId,
      String? title,
      String? description}) async {
    try {
      return Result.success(await remoteTasksRepository.updateTask(
          groupId: groupId,
          taskId: taskId,
          title: title,
          description: description));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> createTask(
      {required String title,
      String? description,
      required int groupId}) async {
    try {
      return Result.success(await remoteTasksRepository.createTask(
          groupId: groupId, title: title, description: description));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> assignTaskToUsers(
      {required int taskId,
      required int groupId,
      required List<int> ids}) async {
    try {
      return Result.success(await remoteTasksRepository.assignTask(
          taskId: taskId, groupId: groupId, ids: ids));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }
}

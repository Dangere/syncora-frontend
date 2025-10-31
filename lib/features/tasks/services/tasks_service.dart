import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';
import 'package:syncora_frontend/features/tasks/repositories/local_tasks_repository.dart';
import 'package:syncora_frontend/features/tasks/repositories/remote_tasks_repository.dart';

class TasksService {
  final LocalTasksRepository _localTasksRepository;
  final RemoteTasksRepository _remoteTasksRepository;

  TasksService(
      {required LocalTasksRepository localTasksRepository,
      required RemoteTasksRepository remoteTasksRepository})
      : _remoteTasksRepository = remoteTasksRepository,
        _localTasksRepository = localTasksRepository;

  Future<Result<List<Task>>> getTasksForGroup(int groupId) async {
    try {
      List<Task> tasks = await _localTasksRepository.getTasksForGroup(groupId);
      return Result.success(tasks);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> deleteTask(
      {required int taskId, required int groupId}) async {
    try {
      return Result.success(
          await _localTasksRepository.markTaskAsDeleted(taskId));
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
      return Result.success(await _remoteTasksRepository.updateTask(
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
      return Result.success(await _remoteTasksRepository.createTask(
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
      return Result.success(await _remoteTasksRepository.assignTask(
          taskId: taskId, groupId: groupId, ids: ids));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> setAssignedUsersToTask(
      {required int taskId,
      required int groupId,
      required List<int> ids}) async {
    try {
      return Result.success(await _remoteTasksRepository.setAssignTask(
          taskId: taskId, groupId: groupId, ids: ids));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> markTask(
      {required int taskId, required int groupId, required bool isDone}) async {
    try {
      return Result.success(await _remoteTasksRepository.markTask(
        taskId: taskId,
        groupId: groupId,
        isDone: isDone,
      ));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }
}

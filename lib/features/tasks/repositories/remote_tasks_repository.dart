import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/features/tasks/models/task.dart';

class RemoteTasksRepository {
  final Dio _dio;

  RemoteTasksRepository({required Dio dio}) : _dio = dio;

  Future<Task> createTask(
      {required String title,
      String? description,
      required int groupId}) async {
    final response = await _dio
        .post('${Constants.BASE_API_URL}/groups/$groupId/tasks', data: {
      "title": title,
      "description": description,
    }).timeout(const Duration(seconds: 10));

    return Task.fromJson(response.data);
  }

  Future<void> deleteTask({required int taskId, required int groupId}) async {
    await _dio
        .delete('${Constants.BASE_API_URL}/groups/$groupId/tasks/$taskId')
        .timeout(const Duration(seconds: 10));
  }

  Future<void> updateTask(
      {required int taskId,
      required int groupId,
      String? title,
      String? description}) async {
    await _dio.put('${Constants.BASE_API_URL}/groups/$groupId/tasks/$taskId',
        data: {
          "title": title,
          "description": description
        }).timeout(const Duration(seconds: 10));
  }

  Future<void> assignTask(
      {required int taskId,
      required int groupId,
      required List<int> ids}) async {
    if (ids.isEmpty) {
      throw Exception('No users selected');
    }

    String idsString = ids.map((id) => 'ids=$id').join("&");

    await _dio
        .put(
          '${Constants.BASE_API_URL}/groups/$groupId/tasks/$taskId/assign?$idsString',
        )
        .timeout(const Duration(seconds: 10));
  }

  // Directly sets the list of users assigned to a task
  Future<void> setAssignTask(
      {required int taskId,
      required int groupId,
      required List<int> ids}) async {
    String idsString = ids.map((id) => 'ids=$id').join("&");

    await _dio
        .put(
          '${Constants.BASE_API_URL}/groups/$groupId/tasks/$taskId/set-assign?$idsString',
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<void> markTask(
      {required int taskId, required int groupId, required bool isDone}) async {
    await _dio
        .put(
          '${Constants.BASE_API_URL}/groups/$groupId/tasks/$taskId/mark?isDone=$isDone',
        )
        .timeout(const Duration(seconds: 10));
  }
}

import 'package:dio/dio.dart';
import 'package:syncora_frontend/core/constants/constants.dart';

class RemoteTasksRepository {
  final Dio _dio;

  RemoteTasksRepository({required Dio dio}) : _dio = dio;

  Future<void> createTask(
      {required String title,
      String? description,
      required int groupId}) async {
    await _dio.post('${Constants.BASE_API_URL}/groups/$groupId/tasks', data: {
      "title": title,
      "description": description,
    }).timeout(const Duration(seconds: 10));
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
      String? description,
      bool? completed}) async {
    await _dio.put('${Constants.BASE_API_URL}/groups/$groupId/tasks/$taskId',
        data: {
          "title": title,
          "description": description,
          "completed": completed
        }).timeout(const Duration(seconds: 10));
  }
}

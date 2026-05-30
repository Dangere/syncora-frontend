import 'package:dio/dio.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/features/users/models/user.dart';
import 'package:syncora_frontend/features/groups/models/group_dto.dart';

/// Class used to do remote API CRUD operations for groups
class RemoteGroupsRepository {
  final Dio _dio;

  RemoteGroupsRepository({required Dio dio}) : _dio = dio;

  Future<GroupDTO> createGroup(
      {required String title, String? description}) async {
    final response = await _dio.post('${Constants.BASE_API_URL}/groups', data: {
      "title": title,
      "description": description
    }).timeout(const Duration(seconds: 10));

    return GroupDTO.fromJson(response.data);
  }

  Future<void> updateGroupDetails(
      {String? title, String? description, required int groupId}) async {
    await _dio.put('${Constants.BASE_API_URL}/groups/$groupId', data: {
      "title": title,
      "description": description
    }).timeout(const Duration(seconds: 10));
  }

  Future<List<User>> addUsersToGroup(
      {required List<String> usernames, required int groupId}) async {
    var response = await _dio
        .post('${Constants.BASE_API_URL}/groups/$groupId/grant-access',
            options: Options(
              contentType: 'application/json',
            ),
            data: usernames)
        .timeout(const Duration(seconds: 10));

    List<User> users =
        (response.data as List).map((e) => User.fromJson(e)).toList();
    return users;
  }

  Future<void> removeUsersFromGroup(
      {required List<String> usernames, required int groupId}) async {
    await _dio
        .post('${Constants.BASE_API_URL}/groups/$groupId/revoke-access',
            options: Options(
              contentType: 'application/json',
            ),
            data: usernames)
        .timeout(const Duration(seconds: 10));
  }

  Future<void> leaveGroup(int groupId) async {
    await _dio
        .post('${Constants.BASE_API_URL}/groups/$groupId/leave')
        .timeout(const Duration(seconds: 10));
  }

  Future<void> deleteGroup(int groupId) async {
    await _dio
        .delete('${Constants.BASE_API_URL}/groups/$groupId')
        .timeout(const Duration(seconds: 10));
  }
}

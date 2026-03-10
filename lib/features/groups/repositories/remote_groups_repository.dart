import 'package:dio/dio.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/groups/models/group_dto.dart';

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

  // Future<List<GroupDTO>> getAllGroups() async {
  //   final response = await _dio
  //       .get(
  //         '${Constants.BASE_API_URL}/groups',
  //       )
  //       .timeout(const Duration(seconds: 10));

  //   List<GroupDTO> groups =
  //       (response.data as List).map((e) => GroupDTO.fromJson(e)).toList();

  //   return groups;
  // }

  Future<void> addUsersToGroup(
      {required List<String> usernames, required int groupId}) async {
    await _dio
        .post('${Constants.BASE_API_URL}/groups/$groupId/grant-access',
            options: Options(
              contentType: 'application/json',
            ),
            data: usernames)
        .timeout(const Duration(seconds: 10));
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

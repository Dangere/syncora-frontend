import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/features/groups/interfaces/group_repository_mixin.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';

class RemoteGroupRepository implements GroupRepositoryMixin {
  final Dio _dio;

  RemoteGroupRepository({required Dio dio, required String accessToken})
      : _dio = dio {
    _dio.options.headers["authorization"] = "Bearer $accessToken";
  }

  @override
  Future<Group> createGroup(String title, String description) async {
    final response = await _dio.post('${Constants.BASE_URL}/groups', data: {
      "title": title,
      "description": description
    }).timeout(const Duration(seconds: 10));

    return Group.fromJson(response.data);
  }

  @override
  Future<List<Group>> getAllGroups() async {
    final response = await _dio
        .get(
          '${Constants.BASE_URL}/groups',
        )
        .timeout(const Duration(seconds: 10));

    List<Group> groups =
        (response.data as List).map((e) => Group.fromJson(e)).toList();

    return groups;
  }

  @override
  Future<void> leaveGroup(int groupId) {
    // TODO: implement leaveGroup
    throw UnimplementedError();
  }
}

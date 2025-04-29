import 'package:dio/dio.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/features/groups/interfaces/group_repository_mixin.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';

class RemoteGroupRepository implements GroupRepositoryMixin {
  final Dio _dio;

  RemoteGroupRepository({required Dio dio, required String accessToken})
      : _dio = dio {
    _dio.options.headers["authorization"] = "token $accessToken";
  }

  @override
  Future<void> createGroup(String groupName) {
    // TODO: implement createGroup
    throw UnimplementedError();
  }

  @override
  Future<List<Group>> getAllGroups() async {
    final response = await _dio
        .get(
          '${Constants.BASE_URL}/groups',
        )
        .timeout(const Duration(seconds: 10));

    return (response.data as List).map((e) => Group.fromJson(e)).toList();
  }

  @override
  Future<void> leaveGroup(int groupId) {
    // TODO: implement leaveGroup
    throw UnimplementedError();
  }
}

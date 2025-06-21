import 'package:dio/dio.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';

class RemoteUsersRepository {
  final Dio _dio;

  RemoteUsersRepository({required Dio dio}) : _dio = dio;

  Future<List<User>> getAllUsers() async {
    final response = await _dio
        .get(
          '${Constants.BASE_URL}/users',
        )
        .timeout(const Duration(seconds: 10));

    List<User> users =
        (response.data as List).map((e) => User.fromJson(e)).toList();

    return users;
  }
}

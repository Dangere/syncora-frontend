import 'package:dio/dio.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
// import 'package:syncora_frontend/features/authentication/models/user.dart';

class RemoteUsersRepository {
  final Dio _dio;

  RemoteUsersRepository({required Dio dio}) : _dio = dio;

  Future<void> updateUserProfilePicture(String url) async {
    await _dio.put(
      '${Constants.BASE_API_URL}/users/profile-picture',
      data: {"profilePicture": url},
    ).timeout(const Duration(seconds: 10));
  }
}

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
// import 'package:syncora_frontend/features/authentication/models/user.dart';

class RemoteUsersRepository {
  final Dio _dio;

  RemoteUsersRepository({required Dio dio}) : _dio = dio;

  Future<void> updateUserProfilePicture(String url) async {
    await _dio
        .post(
          '${Constants.BASE_API_URL}/users/images/profile/upload',
          data: jsonEncode(url),
          options: Options(
            contentType: 'application/json',
          ),
        )
        .timeout(const Duration(seconds: 10));
  }
}

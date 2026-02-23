import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/constants/constants.dart';

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

  Future<void> updateUserProfile(
      {String? username, String? firstName, String? lastName}) async {
    Logger().w("$username, $firstName, $lastName");
    await _dio
        .post(
          '${Constants.BASE_API_URL}/users/profile',
          data: {
            "username": username,
            "firstName": firstName,
            "lastName": lastName
          },
          options: Options(
            contentType: 'application/json',
          ),
        )
        .timeout(const Duration(seconds: 10));
  }
}

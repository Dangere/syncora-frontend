import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:intl/locale.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/features/users/models/user.dart';

class RemoteUsersRepository {
  final Dio _dio;

  RemoteUsersRepository({required Dio dio}) : _dio = dio;

  Future<User> getUser(String username) async {
    final response = await _dio
        .get('${Constants.BASE_API_URL}/users/$username')
        .timeout(const Duration(seconds: 10));

    return User.fromJson(response.data);
  }

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

  Future<void> updateUserPreferences(
      {bool? darkMode, String? languageCode}) async {
    await _dio
        .post(
          '${Constants.BASE_API_URL}/users/profile',
          data: {
            "preferences": {"darkMode": darkMode, "languageCode": languageCode}
          },
          options: Options(
            contentType: 'application/json',
          ),
        )
        .timeout(const Duration(seconds: 10));
  }
}

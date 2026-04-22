import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/features/authentication/models/auth_response_dto.dart';
import 'package:syncora_frontend/features/authentication/models/tokens.dart';
import 'package:syncora_frontend/features/users/models/user_preferences.dart';

class AuthRepository {
  final Dio _dio;
  AuthRepository({required Dio dio}) : _dio = dio;

  Future<AuthResponseDTO> loginWithEmailAndPassword(
      {required String email, required String password}) async {
    // Getting the login response
    final response = await _dio
        .post("${Constants.BASE_API_URL}/authentication/login", data: {
      "Email": email,
      "Password": password
    }).timeout(const Duration(seconds: 20));

    AuthResponseDTO authResponse = AuthResponseDTO.fromJson(response.data);

    // Returning the authentication response
    return authResponse;
  }

  Future<AuthResponseDTO> registerWithEmailAndPassword(
      {required String email,
      required String username,
      required String firstName,
      required String lastName,
      required String password,
      UserPreferences? preferences}) async {
    // Getting the register response
    final response = await _dio
        .post("${Constants.BASE_API_URL}/authentication/register", data: {
      "Email": email,
      "Username": username,
      "Password": password,
      "FirstName": firstName,
      "LastName": lastName,
      if (preferences != null)
        "preferences": {
          "darkMode": preferences.darkMode,
          "languageCode": preferences.locale.languageCode
        }
    }).timeout(const Duration(seconds: 20));

    AuthResponseDTO authResponse = AuthResponseDTO.fromJson(response.data);

    // Returning the authentication response
    return authResponse;
  }

  Future<AuthResponseDTO> loginWithGoogle(String idToken) async {
    // Getting the login response
    final response = await _dio
        .post(
          "${Constants.BASE_API_URL}/authentication/login/google",
          data: jsonEncode(idToken),
          options: Options(
            contentType: 'application/json',
          ),
        )
        .timeout(const Duration(seconds: 20));

    AuthResponseDTO authResponse = AuthResponseDTO.fromJson(response.data);

    // Returning the authentication response
    return authResponse;
  }

  // We could first ask for additional information from the user before registering
  Future<AuthResponseDTO> registerWithGoogle(String idToken,
      {required String username,
      required String password,
      required String firstName,
      required String lastName,
      UserPreferences? preferences}) async {
    // Getting the register response
    final response = await _dio.post(
        "${Constants.BASE_API_URL}/authentication/register/google",
        data: {
          "IdToken": idToken,
          "FirstName": firstName,
          "LastName": lastName,
          "Username": username,
          "Password": password,
          if (preferences != null)
            "preferences": {
              "darkMode": preferences.darkMode,
              "languageCode": preferences.locale.languageCode
            }
        }).timeout(const Duration(seconds: 20));

    AuthResponseDTO authResponse = AuthResponseDTO.fromJson(response.data);

    // Returning the authentication response
    return authResponse;
  }

  Future<Tokens> refreshAccessToken({required Tokens tokens}) async {
    // Using a different instance of Dio because the main instance is calling this method
    // To refresh tokens
    Dio dio = Dio();

    final response = await dio
        .post("${Constants.BASE_API_URL}/authentication/refresh-token", data: {
      "RefreshToken": tokens.refreshToken,
      "AccessToken": tokens.accessToken
    }).timeout(const Duration(seconds: 10));

    String fetchedAccessToken = response.data['accessToken'] as String;
    String fetchedRefreshToken = response.data['refreshToken'] as String;

    return Tokens(
        accessToken: fetchedAccessToken, refreshToken: fetchedRefreshToken);
  }

  Future<void> sendVerificationEmail() async {
    await _dio
        .post(
          "${Constants.BASE_API_URL}/authentication/verify/send",
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<bool> checkVerificationStatus() async {
    final response = await _dio
        .post(
          "${Constants.BASE_API_URL}/authentication/verify/status",
        )
        .timeout(const Duration(seconds: 10));

    return response.data as bool;
  }

  Future<void> requestPasswordReset(String email) async {
    await _dio
        .post(
            "${Constants.BASE_API_URL}/authentication/password-reset/send/$email")
        .timeout(const Duration(seconds: 20));
  }
}

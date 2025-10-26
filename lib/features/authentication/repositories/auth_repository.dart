import 'dart:async';

import 'package:dio/dio.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/features/authentication/models/auth_response_dto.dart';
import 'package:syncora_frontend/features/authentication/models/tokens_dto.dart';

class AuthRepository {
  final Dio _dio;
  AuthRepository({required Dio dio}) : _dio = dio;

  Future<AuthResponseDTO> loginWithEmailAndPassword(
      String email, String password) async {
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
      String email, String username, String password) async {
    // Getting the register response
    final response = await _dio
        .post("${Constants.BASE_API_URL}/authentication/register", data: {
      "Email": email,
      "Username": username,
      "Password": password
    }).timeout(const Duration(seconds: 20));

    AuthResponseDTO authResponse = AuthResponseDTO.fromJson(response.data);

    // Returning the authentication response
    return authResponse;
  }

  Future<TokensDTO> refreshAccessToken({required TokensDTO tokens}) async {
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

    return TokensDTO(
        accessToken: fetchedAccessToken, refreshToken: fetchedRefreshToken);
  }

  Future<AuthResponseDTO> loginWithGoogle(String idToken) async {
    // Getting the login response
    final response = await _dio
        .post("${Constants.BASE_API_URL}/authentication/login/google/$idToken")
        .timeout(const Duration(seconds: 20));

    AuthResponseDTO authResponse = AuthResponseDTO.fromJson(response.data);

    // Returning the authentication response
    return authResponse;
  }

  // We could first ask for additional information from the user before registering
  Future<AuthResponseDTO> registerWithGoogle(String idToken,
      {required String username, required String password}) async {
    // Getting the register response
    final response = await _dio.post(
        "${Constants.BASE_API_URL}/authentication/register/google",
        data: {
          "IdToken": idToken,
          "Username": username,
          "Password": password
        }).timeout(const Duration(seconds: 20));

    AuthResponseDTO authResponse = AuthResponseDTO.fromJson(response.data);

    // Returning the authentication response
    return authResponse;
  }
}

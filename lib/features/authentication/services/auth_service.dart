import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_response_dto.dart';
import 'package:syncora_frontend/features/authentication/models/tokens_dto.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/repositories/auth_repository.dart';
import 'package:syncora_frontend/features/authentication/services/session_storage.dart';

class AuthService {
  final AuthRepository _authRepository;

  final SessionStorage _sessionStorage;

  AuthService(
      {required AuthRepository authRepository,
      required SessionStorage sessionStorage})
      : _authRepository = authRepository,
        _sessionStorage = sessionStorage;

  Future<Result<User>> loginWithEmailAndPassword(
      String email, String password) async {
    try {
      AuthResponseDTO loginResponse =
          await _authRepository.loginWithEmailAndPassword(email, password);

      // Storing the session
      await _sessionStorage.saveSession(
          user: loginResponse.user,
          accessToken: loginResponse.tokens.accessToken,
          refreshToken: loginResponse.tokens.refreshToken);

      Logger().w(loginResponse.tokens.accessToken);
      Logger().w(loginResponse.tokens.refreshToken);

      return Result.success(loginResponse.user);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<User>> registerWithEmailAndPassword(
      String email, String username, String password) async {
    try {
      AuthResponseDTO registerResponse = await _authRepository
          .registerWithEmailAndPassword(email, username, password);

      // Storing the session
      await _sessionStorage.saveSession(
          user: registerResponse.user,
          accessToken: registerResponse.tokens.accessToken,
          refreshToken: registerResponse.tokens.refreshToken);

      return Result.success(registerResponse.user);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<User>> loginAsGuest(String username) async {
    User guest = User.guest(username);
    // Storing the user in session without token
    await _sessionStorage.saveSession(user: guest);
    return Result.success(guest);
  }

  Future<Result<TokensDTO>> refreshAccessToken(
      {required TokensDTO tokens, required VoidCallback kickFunc}) async {
    try {
      TokensDTO refreshedTokens =
          await _authRepository.refreshAccessToken(tokens: tokens);
      return Result.success(refreshedTokens);
    } on DioException catch (e, stackTrace) {
      if (e.response?.statusCode == 401) {
        kickFunc();
      }
      return Result.failure(ErrorMapper.map(e, stackTrace));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<void> logout() async {
    await _sessionStorage.clearSession();
  }
}

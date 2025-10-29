import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_response_dto.dart';
import 'package:syncora_frontend/features/authentication/models/google_register_user_info.dart';
import 'package:syncora_frontend/features/authentication/models/tokens_dto.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/repositories/auth_repository.dart';
import 'package:syncora_frontend/features/authentication/services/session_storage.dart';

class AuthService {
  final AuthRepository _authRepository;

  final SessionStorage _sessionStorage;
  final GoogleSignIn googleSignIn = GoogleSignIn(
    serverClientId:
        "740026130263-r929iqqghkj757fu2agvqipo3577b9aj.apps.googleusercontent.com",
    scopes: [
      'email',
    ],
  );

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
          user: loginResponse.user, tokens: loginResponse.tokens);

      // Logger().w(loginResponse.tokens.accessToken);
      // Logger().w(loginResponse.tokens.refreshToken);

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
          user: registerResponse.user, tokens: registerResponse.tokens);

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
      {required TokensDTO tokens, required VoidCallback onExpire}) async {
    try {
      TokensDTO refreshedTokens =
          await _authRepository.refreshAccessToken(tokens: tokens);
      return Result.success(refreshedTokens);
    } on DioException catch (e, stackTrace) {
      if (e.response?.statusCode == 401) {
        onExpire();
      }
      return Result.failure(ErrorMapper.map(e, stackTrace));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<void> logout() async {
    await _sessionStorage.clearSession();
  }

  Future<Result<User>> loginWithGoogle() async {
    if (!(kIsWeb || Platform.isAndroid)) {
      return Result.failureMessage(
          "Google login is only available on Android and Web");
    }

    try {
      // FIXME:  `signIn` method is deprecated on the web, use `renderButton` instead but it reqiures a platform specific implementation
      final GoogleSignInAccount? googleAccount = await googleSignIn.signIn();
      if (googleAccount == null) {
        return Result.failureMessage("Google login failed");
      }

      final GoogleSignInAuthentication googleAuthentication =
          await googleAccount.authentication;

      // This is the JWT token containing the user's identity
      String idToken = googleAuthentication.idToken!;

      // We send it to the backend to verify it and get our own user data and tokens
      AuthResponseDTO loginResponse =
          await _authRepository.loginWithGoogle(idToken);

      Logger().w(loginResponse.user.toJson());

      // Storing the session
      await _sessionStorage.saveSession(
          user: loginResponse.user, tokens: loginResponse.tokens);

      return Result.success(loginResponse.user);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<User>> registerWithGoogle(
      AsyncFunc<String, GoogleRegisterUserInfo?> afterAccountSelect) async {
    if (!(kIsWeb || Platform.isAndroid)) {
      return Result.failureMessage(
          "Google login is only available on Android and Web");
    }

    try {
      final GoogleSignInAccount? googleAccount = await googleSignIn.signIn();
      if (googleAccount == null) {
        return Result.failureMessage("Google registration failed");
      }

      final GoogleSignInAuthentication googleAuthentication =
          await googleAccount.authentication;

      // This is the JWT token containing the user's identity
      String idToken = googleAuthentication.idToken!;

      // We call the delegate to get the username and password from UI pop up
      GoogleRegisterUserInfo? userInfo =
          await afterAccountSelect(googleAccount.email);

      if (userInfo == null) {
        googleSignIn.signOut();
        return Result.failureMessage("Google registration failed");
      }

      // We send it to the backend to verify it and get our own user data and tokens
      AuthResponseDTO registerResponse =
          await _authRepository.registerWithGoogle(idToken,
              username: userInfo.username, password: userInfo.password);

      // Storing the session
      await _sessionStorage.saveSession(
          user: registerResponse.user, tokens: registerResponse.tokens);

      return Result.success(registerResponse.user);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }
}

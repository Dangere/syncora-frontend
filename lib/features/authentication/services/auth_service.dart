import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_response_dto.dart';
import 'package:syncora_frontend/features/authentication/models/google_register_user_info.dart';
import 'package:syncora_frontend/features/authentication/models/tokens_dto.dart';
import 'package:syncora_frontend/features/authentication/repositories/auth_repository.dart';

class AuthService {
  final AuthRepository _authRepository;
  final GoogleSignIn googleSignIn = GoogleSignIn(
    serverClientId: kIsWeb
        ? null
        : "740026130263-r929iqqghkj757fu2agvqipo3577b9aj.apps.googleusercontent.com",
    scopes: [
      'email',
    ],
  );

  AuthService({required AuthRepository authRepository})
      : _authRepository = authRepository;

  Future<Result<AuthResponseDTO>> loginWithEmailAndPassword(
      String email, String password) async {
    try {
      AuthResponseDTO loginResponse =
          await _authRepository.loginWithEmailAndPassword(email, password);
      return Result.success(loginResponse);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<AuthResponseDTO>> registerWithEmailAndPassword(
      String email, String username, String password) async {
    try {
      AuthResponseDTO registerResponse = await _authRepository
          .registerWithEmailAndPassword(email, username, password);

      return Result.success(registerResponse);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
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

  Future<Result<AuthResponseDTO>> loginWithGoogle() async {
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

      return Result.success(loginResponse);
    } catch (e, stackTrace) {
      googleSignIn.signOut();
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<AuthResponseDTO>> registerWithGoogle(
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

      return Result.success(registerResponse);
    } catch (e, stackTrace) {
      googleSignIn.signOut();

      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }
}

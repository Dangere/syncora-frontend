import 'dart:async';
import 'dart:io';
import 'package:cancellation_token/cancellation_token.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_response_dto.dart';
import 'package:syncora_frontend/features/authentication/models/google_register_filled_info.dart';
import 'package:syncora_frontend/features/authentication/models/google_user_info.dart';
import 'package:syncora_frontend/features/authentication/models/tokens.dart';
import 'package:syncora_frontend/features/authentication/auth_repository.dart';
import 'package:syncora_frontend/features/users/models/user_preferences.dart';

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
      {required String email, required String password}) async {
    try {
      AuthResponseDTO loginResponse = await _authRepository
          .loginWithEmailAndPassword(email: email, password: password);
      return Result.success(loginResponse);
    } catch (e, stackTrace) {
      // print("ERRORRRR");
      return Result.failureError(e, stackTrace);
    }
  }

  Future<Result<AuthResponseDTO>> registerWithEmailAndPassword(
      {required String email,
      required String username,
      required String firstName,
      required String lastName,
      required String password,
      required UserPreferences preferences}) async {
    try {
      AuthResponseDTO registerResponse =
          await _authRepository.registerWithEmailAndPassword(
              email: email,
              username: username,
              firstName: firstName,
              lastName: lastName,
              password: password,
              preferences: preferences);

      return Result.success(registerResponse);
    } catch (e, stackTrace) {
      return Result.failureError(e, stackTrace);
    }
  }

  Future<Result<AuthResponseDTO>> loginWithGoogle() async {
    if (!(kIsWeb || Platform.isAndroid)) {
      return Result.canceled(
          "Google login is only available on Android and Web",
          StackTrace.current);
    }
    googleSignIn.signOut();

    try {
      // FIXME:  `signIn` method is deprecated on the web, use `renderButton` instead but it reqiures a platform specific implementation
      final GoogleSignInAccount? googleAccount = await googleSignIn.signIn();
      if (googleAccount == null) {
        return Result.canceled("Google login canceled", StackTrace.current);
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
      return Result.failureError(e, stackTrace);
    }
  }

  Future<Result<AuthResponseDTO>> registerUserWithGoogle(
      GoogleUserInfo googleUserInfo,
      GoogleRegisterFilledInfo userFilledInfo,
      UserPreferences preferences) async {
    if (!(kIsWeb || Platform.isAndroid)) {
      return Result.canceled(
          "Google login is only available on Android and Web",
          StackTrace.current);
    }

    try {
      AuthResponseDTO registerResponse =
          await _authRepository.registerWithGoogle(googleUserInfo.token,
              firstName: userFilledInfo.firstName,
              lastName: userFilledInfo.lastName,
              username: userFilledInfo.username,
              password: userFilledInfo.password,
              preferences: preferences);

      return Result.success(registerResponse);
    } catch (e, stackTrace) {
      googleSignIn.signOut();

      return Result.failureError(e, stackTrace);
    }
  }

  Future<Result<GoogleUserInfo>> getGoogleRegisterToken() async {
    if (!(kIsWeb || Platform.isAndroid)) {
      return Result.canceled(
          "Google login is only available on Android and Web",
          StackTrace.current);
    }
    googleSignIn.signOut();

    try {
      final GoogleSignInAccount? googleAccount = await googleSignIn.signIn();
      if (googleAccount == null) {
        return Result.canceled(
            "Google registration canceled", StackTrace.current);
      }

      final GoogleSignInAuthentication googleAuthentication =
          await googleAccount.authentication;

      // We call the delegate to get the username and password from UI pop up
      List<String> fullName = googleAccount.displayName?.split(" ") ?? [];
      var userInfo = GoogleUserInfo(
          token: googleAuthentication.idToken!,
          email: googleAccount.email,
          firstName: fullName.isNotEmpty ? fullName[0] : "",
          lastName: fullName.length > 1 ? fullName[1] : "");

      return Result.success(userInfo);
    } catch (e, stackTrace) {
      await googleSignIn.signOut();
      return Result.failureError(e, stackTrace);
    }
  }

  Future<Result<Tokens>> refreshAccessToken(
      {required Tokens tokens,
      required VoidCallback onExpire,
      CancellationToken? cancellationToken}) async {
    try {
      Tokens refreshedTokens = await _authRepository
          .refreshAccessToken(tokens: tokens)
          .asCancellable(cancellationToken);
      return Result.success(refreshedTokens);
    } on DioException catch (e, stackTrace) {
      if (e.response?.statusCode == 401) {
        onExpire();
      }
      return Result.failureError(e, stackTrace);
    } catch (e, stackTrace) {
      return Result.failureError(e, stackTrace);
    }
  }

  Future<Result<void>> sendVerificationEmail() async {
    try {
      await _authRepository.sendVerificationEmail();

      return Result.success();
    } catch (e, stackTrace) {
      return Result.failureError(e, stackTrace);
    }
  }

  Future<Result<bool>> checkVerificationStatus() async {
    try {
      return Result.success(await _authRepository.checkVerificationStatus());
    } catch (e, stackTrace) {
      return Result.failureError(e, stackTrace);
    }
  }

  Future<Result<void>> requestPasswordReset(String email) async {
    try {
      await _authRepository.requestPasswordReset(email);
      return Result.success();
    } catch (e, stackTrace) {
      return Result.failureError(e, stackTrace);
    }
  }

  Future<void> googleSignOut() async {
    if (await googleSignIn.isSignedIn()) await googleSignIn.signOut();
  }
}

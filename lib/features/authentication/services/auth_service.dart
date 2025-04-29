import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_response_dto.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/repository/auth_repository.dart';

class AuthService {
  final AuthRepository _authRepository;
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _sharedPreferences;

  AuthService(
      {required AuthRepository authRepository,
      required FlutterSecureStorage secureStorage,
      required SharedPreferences sharedPreferences})
      : _authRepository = authRepository,
        _secureStorage = secureStorage,
        _sharedPreferences = sharedPreferences;

  Future<Result<User>> loginWithEmailAndPassword(
      String email, String password) async {
    try {
      AuthResponseDTO loginResponse =
          await _authRepository.loginWithEmailAndPassword(email, password);

      // Storing the token
      await _secureStorage.write(
          key: "jwt_token", value: loginResponse.accessToken);
      // Storing the user
      _sharedPreferences.setString("user", json.encode(loginResponse.user));
      return Result.success(loginResponse.user);
    } catch (e) {
      return Result.failure(ErrorMapper.map(e));
    }
  }

  Future<Result<User>> registerWithEmailAndPassword(
      String email, String username, String password) async {
    try {
      AuthResponseDTO loginResponse = await _authRepository
          .registerWithEmailAndPassword(email, username, password);

      // Storing the token
      await _secureStorage.write(
          key: "jwt_token", value: loginResponse.accessToken);

      // Storing the user
      await _sharedPreferences.setString(
          "user", json.encode(loginResponse.user));

      return Result.success(loginResponse.user);
    } catch (e) {
      return Result.failure(ErrorMapper.map(e));
    }
  }

  Future<Result<User>> loginAsGuest(String username) async {
    User guest = User.guest(username);
    // Storing the user
    await _sharedPreferences.setString("user", json.encode(guest));
    return Future.value(Result.success(guest));
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: "jwt_token");

    await _sharedPreferences.remove("user");
  }

  Future<String?> getCachedToken() async {
    return _secureStorage.read(key: "jwt_token");
  }

  User? getCachedUser() {
    String? userJson = _sharedPreferences.getString("user");

    if (userJson != null) {
      return User.fromJson(json.decode(userJson));
    }

    return null;
  }
}

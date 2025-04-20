import 'dart:async';

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

      await _secureStorage.write(
          key: "jwt_token", value: loginResponse.accessToken);

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
      await _secureStorage.write(
          key: "jwt_token", value: loginResponse.accessToken);
      return Result.success(loginResponse.user);
    } catch (e) {
      return Result.failure(ErrorMapper.map(e));
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: "jwt_token");
  }

  Future<String?> getToken() async {
    return _secureStorage.read(key: "jwt_token");
  }
}

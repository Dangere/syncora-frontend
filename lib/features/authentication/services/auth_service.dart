import 'dart:async';

import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_response_dto.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/repository/auth_repository.dart';

class AuthService {
  final AuthRepository _authRepository;
  AuthService({required AuthRepository authRepository})
      : _authRepository = authRepository;

  Future<Result<User>> loginWithEmailAndPassword(
      String email, String password) async {
    try {
      AuthResponseDTO loginResponse =
          await _authRepository.loginWithEmailAndPassword(email, password);

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

      return Result.success(loginResponse.user);
    } catch (e) {
      return Result.failure(ErrorMapper.map(e));
    }
  }
}

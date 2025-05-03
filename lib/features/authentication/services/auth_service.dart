import 'dart:async';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_response_dto.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/repository/auth_repository.dart';
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
          loginResponse.user, loginResponse.accessToken);

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
          registerResponse.user, registerResponse.accessToken);

      return Result.success(registerResponse.user);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<User>> loginAsGuest(String username) async {
    User guest = User.guest(username);
    // Storing the user in session without token
    await _sessionStorage.saveSession(guest, null);
    return Result.success(guest);
  }

  Future<void> logout() async {
    await _sessionStorage.clearSession();
  }
}

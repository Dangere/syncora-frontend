import 'package:dio/dio.dart';
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
    } on DioException catch (e) {
      if (e.response == null) {
        return Result.failure(e.message!);
      }
      if (e.response!.statusCode == 429) {
        return Result.failure("Too many requests");
      }

      return Result.failure(e.response!.data.toString());
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<User>> registerWithEmailAndPassword(
      String email, String username, String password) async {
    try {
      AuthResponseDTO loginResponse = await _authRepository
          .registerWithEmailAndPassword(email, username, password);

      return Result.success(loginResponse.user);
    } on DioException catch (e) {
      if (e.response == null) {
        return Result.failure(e.message!);
      }
      if (e.response!.statusCode == 429) {
        return Result.failure("Too many requests");
      }

      return Result.failure(e.response!.data.toString());
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}

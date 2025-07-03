import 'package:dio/dio.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/features/authentication/models/auth_response_dto.dart';

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
    }).timeout(const Duration(seconds: 10));

    AuthResponseDTO authResponse = AuthResponseDTO.fromJson(response.data);

    // Returning the authentication response
    return authResponse;
  }

  Future<AuthResponseDTO> registerWithEmailAndPassword(
      String email, String username, String password) async {
    // Getting the login response
    final response = await _dio
        .post("${Constants.BASE_API_URL}/authentication/register", data: {
      "Email": email,
      "Username": username,
      "Password": password
    }).timeout(const Duration(seconds: 10));

    AuthResponseDTO authResponse = AuthResponseDTO.fromJson(response.data);

    // Returning the authentication response
    return authResponse;
  }
}

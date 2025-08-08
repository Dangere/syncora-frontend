import 'package:syncora_frontend/features/authentication/models/user.dart';

class AuthResponseDTO {
  final String accessToken;
  final String refreshToken;

  final User user;

  AuthResponseDTO(
      {required this.accessToken,
      required this.refreshToken,
      required this.user});

  factory AuthResponseDTO.fromJson(Map<String, dynamic> json) {
    return AuthResponseDTO(
        accessToken: json['tokens']['accessToken'],
        refreshToken: json['accessToken']['refreshToken'],
        user: User.fromJson(json['userData']));
  }
}

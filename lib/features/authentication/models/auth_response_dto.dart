import 'package:syncora_frontend/features/authentication/models/user.dart';

class AuthResponseDTO {
  final String accessToken;
  final User user;

  AuthResponseDTO({required this.accessToken, required this.user});

  factory AuthResponseDTO.fromJson(Map<String, dynamic> json) {
    return AuthResponseDTO(
        accessToken: json['accessToken'],
        user: User.fromJson(json['userData']));
  }
}

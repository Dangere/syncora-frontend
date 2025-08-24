import 'package:syncora_frontend/features/authentication/models/tokens_dto.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';

class AuthResponseDTO {
  final TokensDTO tokens;

  final User user;

  AuthResponseDTO({required this.tokens, required this.user});

  factory AuthResponseDTO.fromJson(Map<String, dynamic> json) {
    return AuthResponseDTO(
        tokens: TokensDTO(
            accessToken: json['tokens']['accessToken'],
            refreshToken: json['tokens']['refreshToken']),
        user: User.fromJson(json['userData']));
  }
}

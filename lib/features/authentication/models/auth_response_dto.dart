import 'package:syncora_frontend/features/authentication/models/tokens_dto.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';

class AuthResponseDTO {
  final User user;
  final TokensDTO tokens;
  final bool isVerified;

  AuthResponseDTO(
      {required this.user, required this.tokens, required this.isVerified});

  factory AuthResponseDTO.fromJson(Map<String, dynamic> json) {
    return AuthResponseDTO(
        isVerified: bool.parse(json['isVerified'] ?? 'false'),
        tokens: TokensDTO(
            accessToken: json['tokens']['accessToken'],
            refreshToken: json['tokens']['refreshToken']),
        user: User.fromJson(json['userData']));
  }
}

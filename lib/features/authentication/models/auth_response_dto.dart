import 'package:syncora_frontend/features/authentication/models/tokens.dart';
import 'package:syncora_frontend/features/users/models/user.dart';
import 'package:syncora_frontend/features/users/models/user_preferences.dart';

class AuthResponseDTO {
  final User user;
  final Tokens tokens;
  final bool isVerified;
  final UserPreferences userPreferences;

  AuthResponseDTO(
      {required this.user,
      required this.tokens,
      required this.isVerified,
      required this.userPreferences});

  factory AuthResponseDTO.fromJson(Map<String, dynamic> json) {
    return AuthResponseDTO(
      isVerified: json['isVerified'],
      tokens: Tokens.fromJson(json['tokens']),
      user: User.fromJson(
        json['userData'],
      ),
      userPreferences: UserPreferences.fromJson(json['userPreferences']),
    );
  }
}

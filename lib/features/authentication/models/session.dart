import 'package:syncora_frontend/features/authentication/models/tokens.dart';
import 'package:syncora_frontend/features/users/models/user_preferences.dart';

class Session {
  final int userId;
  bool isVerified;
  Tokens? tokens;

  Session({required this.userId, required this.isVerified, this.tokens});
}

import 'package:syncora_frontend/features/authentication/models/tokens_dto.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';

class Session {
  final User user;
  bool isVerified;
  TokensDTO? tokens;

  Session({required this.user, required this.isVerified, this.tokens});
}

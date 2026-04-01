import 'package:syncora_frontend/features/authentication/models/tokens_dto.dart';

class Session {
  final int userId;
  bool isVerified;
  TokensDTO? tokens;

  Session({required this.userId, required this.isVerified, this.tokens});
}

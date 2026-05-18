import 'package:syncora_frontend/features/authentication/models/tokens.dart';

class Session {
  final int userId;
  bool isVerified;
  Tokens? tokens;

  Session({required this.userId, required this.isVerified, this.tokens});

  Map<String, dynamic> toJson() => {"userId": userId, "isVerified": isVerified};
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/features/authentication/models/User.dart';

class AuthNotifier extends Notifier<User?> {
  void setUser(User? user) {
    state = user;
  }

  @override
  User? build() {
    return null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

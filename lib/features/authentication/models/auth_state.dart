import 'package:syncora_frontend/features/authentication/models/user.dart';

/// Authentication states representing different user authentication scenarios.
/// Each state represents a distinct authentication status in the application.
abstract class AuthState {
  const AuthState();
}

class AuthAuthenticated extends AuthState {
  final User user;
  final bool isVerified;
  const AuthAuthenticated(this.user, this.isVerified);
}

class AuthGuest extends AuthState {
  final User user;

  const AuthGuest(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

extension AuthStateX on AuthState {
  bool get isAuthenticated => this is AuthAuthenticated;
  bool get isUnauthenticated => this is AuthUnauthenticated;

  bool get isGuest => this is AuthGuest;
  User? get user => switch (this) {
        AuthAuthenticated u => u.user,
        AuthGuest g => g.user,
        _ => null,
      };
}

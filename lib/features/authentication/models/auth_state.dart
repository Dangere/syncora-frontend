/// Authentication states representing different user authentication scenarios.
/// Each state represents a distinct authentication status in the application.
abstract class AuthState {
  const AuthState();
}

class AuthAuthenticated extends AuthState {
  final int userId;
  final bool isVerified;
  const AuthAuthenticated(this.userId, this.isVerified);

  AuthAuthenticated copyWith({int? userId, bool? isVerified}) =>
      AuthAuthenticated(userId ?? this.userId, isVerified ?? this.isVerified);
}

class AuthGuest extends AuthState {
  const AuthGuest();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

extension AuthStateX on AuthState {
  bool get isAuthenticated => this is AuthAuthenticated;
  AuthAuthenticated? get asAuthenticated =>
      this is AuthAuthenticated ? this as AuthAuthenticated : null;

  bool get isUnauthenticated => this is AuthUnauthenticated;

  bool get isGuest => this is AuthGuest;
  int? get userId => switch (this) {
        AuthAuthenticated u => u.userId,
        AuthGuest _ => -1,
        _ => null,
      };
}

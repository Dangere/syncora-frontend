import 'package:syncora_frontend/features/authentication/models/user.dart';

class AuthState {
  final bool isGuest;
  final bool isLoading;
  final String? error;
  final User? user;

  AuthState(
      {required this.isLoading, this.isGuest = false, this.error, this.user});

  factory AuthState.logout() => AuthState(isLoading: false, user: null);
}

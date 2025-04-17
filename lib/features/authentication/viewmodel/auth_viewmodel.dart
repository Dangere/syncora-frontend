import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/repository/auth_repository.dart';
import 'package:syncora_frontend/features/authentication/services/auth_service.dart';

class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;

  void loginWithEmailAndPassword(String email, String password) async {
    if (state.user != null) return;

    state = AuthState(isLoading: true);
    Result<User> result =
        await _authService.loginWithEmailAndPassword(email, password);

    if (result.isSuccess) {
      state = AuthState(isLoading: false, user: result.data);
    } else {
      state = AuthState(isLoading: false, error: result.error);
    }
  }

  void registerWithEmailAndPassword(
      String email, String username, String password) async {
    if (state.user != null) return;

    state = AuthState(isLoading: true);
    Result<User> result = await _authService.registerWithEmailAndPassword(
        email, username, password);

    if (result.isSuccess) {
      state = AuthState(isLoading: false, user: result.data);
    } else {
      state = AuthState(isLoading: false, error: result.error);
    }
  }

  void logout() async {
    state = AuthState.logout();
  }

  @override
  AuthState build() {
    _authService = ref.read(authServiceProvider);
    return AuthState(isLoading: false, user: null, error: null);
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final dioProvider = Provider<Dio>((ref) => Dio());

final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => AuthRepository(dio: ref.read(dioProvider)));

final authServiceProvider = Provider<AuthService>(
    (ref) => AuthService(authRepository: ref.read(authRepositoryProvider)));

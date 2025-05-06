import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/repository/auth_repository.dart';
import 'package:syncora_frontend/features/authentication/services/auth_service.dart';
import 'package:syncora_frontend/features/authentication/services/session_storage.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  late final AuthService _authService;
  late final SessionStorage _sessionStorage;

  void loginWithEmailAndPassword(String email, String password) async {
    if (state.value!.isAuthenticated || state.value!.isGuest) return;

    state = const AsyncValue.loading();
    Result<User> result =
        await _authService.loginWithEmailAndPassword(email, password);

    if (result.isSuccess) {
      state = AsyncValue.data(AuthAuthenticated(result.data!));
    } else {
      ref.read(appErrorProvider.notifier).state = result.error!;
      state = const AsyncValue.data(AuthUnauthenticated());
    }
  }

  void registerWithEmailAndPassword(
      String email, String username, String password) async {
    if (state.value!.isAuthenticated || state.value!.isGuest) return;

    state = const AsyncValue.loading();
    Result<User> result = await _authService.registerWithEmailAndPassword(
        email, username, password);

    if (result.isSuccess) {
      state = AsyncValue.data(AuthAuthenticated(result.data!));
    } else {
      ref.read(appErrorProvider.notifier).state = result.error;
      state = const AsyncValue.data(AuthUnauthenticated());
    }
  }

  void loginAsGuest(String username) async {
    if (state.value!.isAuthenticated || state.value!.isGuest) return;

    state = const AsyncValue.loading();
    Result<User> result = await _authService.loginAsGuest(username);

    if (result.isSuccess) {
      state = AsyncValue.data(AuthAuthenticated(result.data!));
    } else {
      ref.read(appErrorProvider.notifier).state = result.error;
      state = const AsyncValue.data(AuthUnauthenticated());
    }
  }

  void logout() async {
    await _authService.logout();
    state = const AsyncValue.data(AuthUnauthenticated());
  }

  @override
  Future<AuthState> build() async {
    _authService = await ref.read(authServiceProvider);
    _sessionStorage = await ref.read(sessionStorageProvider);

    User? user = await _sessionStorage.loadSession();
    if (user == null) return const AuthUnauthenticated();

    if (user.id == -1) return AuthGuest(user);

    return AuthAuthenticated(user);
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => AuthRepository(dio: ref.read(dioProvider)));

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
      authRepository: ref.read(authRepositoryProvider),
      sessionStorage: ref.read(sessionStorageProvider));
});

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SessionStorage(
      secureStorage: ref.read(secureStorageProvider),
      sharedPreferences: ref.read(sharedPreferencesProvider));
});

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/repository/auth_repository.dart';
import 'package:syncora_frontend/features/authentication/services/auth_service.dart';
import 'package:syncora_frontend/features/authentication/services/session_storage.dart';

class AuthNotifier extends AsyncNotifier<User?> {
  late final AuthService _authService;
  late final SessionStorage _sessionStorage;

  void loginWithEmailAndPassword(String email, String password) async {
    if (state.value != null) return;

    state = const AsyncValue.loading();
    Result<User> result =
        await _authService.loginWithEmailAndPassword(email, password);

    if (result.isSuccess) {
      state = AsyncValue.data(result.data);
    } else {
      state = AsyncValue.error(result.error!, StackTrace.current);
    }
  }

  void registerWithEmailAndPassword(
      String email, String username, String password) async {
    if (state.value != null) return;
    state = const AsyncValue.loading();
    Result<User> result = await _authService.registerWithEmailAndPassword(
        email, username, password);

    if (result.isSuccess) {
      state = AsyncValue.data(result.data);
    } else {
      state = AsyncValue.error(result.error!, StackTrace.current);
    }
  }

  void loginAsGuest(String username) async {
    if (state.value != null) return;
    state = const AsyncValue.loading();
    Result<User> result = await _authService.loginAsGuest(username);

    if (result.isSuccess) {
      state = AsyncValue.data(result.data);
    } else {
      state = AsyncValue.error(result.error!, StackTrace.current);
    }
  }

  void logout() async {
    await _authService.logout();
    state = const AsyncValue.data(null);
  }

  @override
  FutureOr<User?> build() async {
    _authService = await ref.read(authServiceProvider);
    _sessionStorage = await ref.read(sessionStorageProvider);

    return await _sessionStorage.loadSession();
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

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

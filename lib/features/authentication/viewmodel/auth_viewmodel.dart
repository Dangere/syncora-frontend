import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/repositories/auth_repository.dart';
import 'package:syncora_frontend/features/authentication/services/auth_service.dart';
import 'package:syncora_frontend/features/authentication/services/session_storage.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  // final AuthService _authService;

  void loginWithEmailAndPassword(String email, String password) async {
    if (state.isLoading || _isLoggedIn) return;

    state = const AsyncValue.loading();
    Result<User> result = await ref
        .read(authServiceProvider)
        .loginWithEmailAndPassword(email, password);

    if (result.isSuccess) {
      state = AsyncValue.data(AuthAuthenticated(result.data!));
    } else {
      ref.read(appErrorProvider.notifier).state = result.error!;
      state = const AsyncValue.data(AuthUnauthenticated());
    }
  }

  void registerWithEmailAndPassword(
      String email, String username, String password) async {
    if (state.isLoading || _isLoggedIn) return;

    state = const AsyncValue.loading();
    Result<User> result = await ref
        .read(authServiceProvider)
        .registerWithEmailAndPassword(email, username, password);

    if (result.isSuccess) {
      state = AsyncValue.data(AuthAuthenticated(result.data!));
    } else {
      ref.read(appErrorProvider.notifier).state = result.error;
      state = const AsyncValue.data(AuthUnauthenticated());
    }
  }

  void loginAsGuest(String username) async {
    if (state.isLoading || _isLoggedIn) return;

    state = const AsyncValue.loading();
    Result<User> result =
        await ref.read(authServiceProvider).loginAsGuest(username);

    if (result.isSuccess) {
      state = AsyncValue.data(AuthGuest(result.data!));
    } else {
      ref.read(appErrorProvider.notifier).state = result.error;
      state = const AsyncValue.data(AuthUnauthenticated());
    }
  }

  void logout() async {
    await ref.read(authServiceProvider).logout();
    state = const AsyncValue.data(AuthUnauthenticated());
  }

  // Value can be null when we are loading or theres an error,
  // even tho i dont throw errors when it happens and instead capture it in an AppError provider,
  // edge cases can happen and the notifier automatically wraps the throws into an AsyncValue.error
  bool get _isLoggedIn {
    final value = state.valueOrNull;
    return value?.isAuthenticated == true || value?.isGuest == true;
  }

  Future<User?> loadSession() async {
    return await ref.read(sessionStorageProvider).loadSession();
  }

  @override
  Future<AuthState> build() async {
    ref.read(loggerProvider).w("building auth notifier");

    User? user = await loadSession();
    if (user == null) return const AuthUnauthenticated();

    if (user.id == -1) return AuthGuest(user);

    return AuthAuthenticated(user);
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => AuthRepository(dio: ref.watch(dioProvider)));

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
      authRepository: ref.watch(authRepositoryProvider),
      sessionStorage: ref.watch(sessionStorageProvider));
});

final isLoggedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider.select((authState) {
    if (authState.value == null) return false;

    return authState.value!.isAuthenticated || authState.value!.isGuest;
  }));
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider.select((authState) {
    if (authState.value == null) return false;

    return authState.value!.isAuthenticated;
  }));
});

final isGuestProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider.select((authState) {
    if (authState.value == null) return true;

    return authState.value!.isGuest;
  }));
});

// final guestFlagProvider = Provider<bool>((ref) {
//   return ref.watch(
//       authNotifierProvider.select((state) => state.value?.isGuest ?? false));
// });

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  ref.read(loggerProvider).d("Constructing session storage");
  return SessionStorage(
      secureStorage: ref.watch(secureStorageProvider),
      sharedPreferences: ref.watch(sharedPreferencesProvider),
      databaseManager: ref.watch(localDbProvider));
});

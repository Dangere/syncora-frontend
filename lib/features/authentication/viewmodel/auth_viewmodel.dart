import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/tests.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/models/google_register_user_info.dart';
import 'package:syncora_frontend/features/authentication/models/tokens_dto.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/repositories/auth_repository.dart';
import 'package:syncora_frontend/features/authentication/services/auth_service.dart';
import 'package:syncora_frontend/features/authentication/services/session_storage.dart';
import 'package:syncora_frontend/features/users/viewmodel/users_providers.dart';

// TODO: Implement guard for connection checking before methods
class AuthNotifier extends AsyncNotifier<AuthState> {
  Completer? _refreshTokenCompleter;

  void loginUsingGoogle() async {
    if (state.isLoading || _isLoggedIn) return;

    state = const AsyncValue.loading();
    Result<User> result = await ref.read(authServiceProvider).loginWithGoogle();
    if (result.isSuccess) {
      state = AsyncValue.data(AuthAuthenticated(result.data!));
    } else {
      ref.read(appErrorProvider.notifier).state = result.error!;
      state = const AsyncValue.data(AuthUnauthenticated());
    }
  }

  void registerUsingGoogle(
      AsyncFunc<String, GoogleRegisterUserInfo?> afterAccountSelect) async {
    if (state.isLoading || _isLoggedIn) return;

    state = const AsyncValue.loading();
    Result<User> result = await ref
        .read(authServiceProvider)
        .registerWithGoogle(afterAccountSelect);

    if (result.isSuccess) {
      state = AsyncValue.data(AuthAuthenticated(result.data!));
    } else {
      ref.read(appErrorProvider.notifier).state = result.error!;
      state = const AsyncValue.data(AuthUnauthenticated());
    }
  }

  void loginWithEmailAndPassword(String email, String password) async {
    if (state.isLoading || _isLoggedIn) return;

    state = const AsyncValue.loading();
    Result<User> result = await ref
        .read(authServiceProvider)
        .loginWithEmailAndPassword(email, password);
    Tests.printDb(await ref.read(localDbProvider).getDatabase());
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

  void kickUser() async {
    logout();

    // TODO: Show pop up instead of snackbar
    // TODO: in the future make it so you can differentiate between a revoked refresh token or an expired, and give different messages
    ref.read(appErrorProvider.notifier).state = AppError(
        message:
            "Your session was either expired or revoked, please login again");
  }

  Future<Result> refreshTokens() async {
    if (state.value == null || !state.value!.isAuthenticated) {
      return Result.failure(
          AppError(message: "Cannot refresh tokens when no user is logged in"));
    }

    String? accessToken = ref.read(sessionStorageProvider).accessToken;
    String? refreshToken = ref.read(sessionStorageProvider).refreshToken;
    if (accessToken == null || refreshToken == null) {
      return Result.failure(
          AppError(message: "Tokens are empty, cannot refresh them"));
    }

    if (_refreshTokenCompleter != null) {
      await _refreshTokenCompleter?.future;
      // Right now second callers to this method will only wait for the first caller to finish refreshing the tokens
      // For all of them and it will return, but if it fails it will also return and the second callers wont know either.
      // Refactor this part
      return Result.success(null);
    }

    _refreshTokenCompleter = Completer();

    ref.read(loggerProvider).d("Refreshing tokens");
    Result<TokensDTO> result = await ref
        .read(authServiceProvider)
        .refreshAccessToken(
            tokens:
                TokensDTO(accessToken: accessToken, refreshToken: refreshToken),
            onExpire: kickUser);

    if (!result.isSuccess) {
      if (!_refreshTokenCompleter!.isCompleted) {
        // _refreshTokenCompleter?.completeError("failed to refresh tokens");
      }

      _refreshTokenCompleter = null;
    }

    await ref.read(sessionStorageProvider).updateTokens(
        accessToken: result.data!.accessToken,
        refreshToken: result.data!.refreshToken);
    _refreshTokenCompleter!.complete();
    _refreshTokenCompleter = null;

    return result;
  }

  // Value can be null when we are loading or theres an error,
  // even tho i dont throw errors when it happens and instead capture it in an AppError provider,
  // edge cases can happen and the notifier automatically wraps the throws into an AsyncValue.error
  bool get _isLoggedIn {
    final value = state.valueOrNull;
    return value?.isAuthenticated == true || value?.isGuest == true;
  }

  Future<User?> loadSession() async {
    ref.read(loggerProvider).w("Making up a user");

    // return new User(id: -1, username: "username", email: "email");
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

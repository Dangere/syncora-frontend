import 'dart:async';
import 'package:cancellation_token/cancellation_token.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_response_dto.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/models/google_register_user_info.dart';
import 'package:syncora_frontend/features/authentication/models/session.dart';
import 'package:syncora_frontend/features/authentication/models/tokens_dto.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/repositories/auth_repository.dart';
import 'package:syncora_frontend/features/authentication/services/auth_service.dart';
import 'package:syncora_frontend/features/authentication/services/session_storage.dart';

// TODO: Implement guard for connection checking before methods

class AuthNotifier extends AsyncNotifier<AuthState> {
  Completer? _refreshTokenCompleter;

  void loginUsingGoogle() async {
    if (state.isLoading || _isLoggedIn) return;

    state = const AsyncValue.loading();

    Result<AuthResponseDTO> result =
        await ref.read(authServiceProvider).loginWithGoogle();

    if (result.isSuccess) {
      // Save session
      await ref.read(sessionStorageProvider).saveSession(
          user: result.data!.user,
          tokens: result.data!.tokens,
          isVerified: result.data!.isVerified);
      // Update state
      state = AsyncValue.data(
          AuthAuthenticated(result.data!.user, result.data!.isVerified));
    } else {
      ref.read(appErrorProvider.notifier).state = result.error!;
      state = const AsyncValue.data(AuthUnauthenticated());
    }
  }

  void registerUsingGoogle(
      AsyncFunc<String, GoogleRegisterUserInfo?> afterAccountSelect) async {
    if (state.isLoading || _isLoggedIn) return;

    state = const AsyncValue.loading();

    Result<AuthResponseDTO> result = await ref
        .read(authServiceProvider)
        .registerWithGoogle(afterAccountSelect);

    if (result.isSuccess) {
      // Save session
      await ref.read(sessionStorageProvider).saveSession(
          user: result.data!.user,
          tokens: result.data!.tokens,
          isVerified: result.data!.isVerified);
      // Update state
      state = AsyncValue.data(
          AuthAuthenticated(result.data!.user, result.data!.isVerified));
    } else {
      ref.read(appErrorProvider.notifier).state = result.error!;
      state = const AsyncValue.data(AuthUnauthenticated());
    }
  }

  void loginWithEmailAndPassword(String email, String password) async {
    if (state.isLoading || _isLoggedIn) return;

    state = const AsyncValue.loading();

    Result<AuthResponseDTO> result = await ref
        .read(authServiceProvider)
        .loginWithEmailAndPassword(email, password);

    if (result.isSuccess) {
      // Save session
      await ref.read(sessionStorageProvider).saveSession(
          user: result.data!.user,
          tokens: result.data!.tokens,
          isVerified: result.data!.isVerified);

      // Update state
      state = AsyncValue.data(
          AuthAuthenticated(result.data!.user, result.data!.isVerified));
    } else {
      ref.read(appErrorProvider.notifier).state = result.error!;
      state = const AsyncValue.data(AuthUnauthenticated());
    }
  }

  void registerWithEmailAndPassword(
      String email, String username, String password) async {
    if (state.isLoading || _isLoggedIn) return;

    state = const AsyncValue.loading();

    Result<AuthResponseDTO> result = await ref
        .read(authServiceProvider)
        .registerWithEmailAndPassword(email, username, password);

    if (result.isSuccess) {
      // Save session
      await ref.read(sessionStorageProvider).saveSession(
          user: result.data!.user,
          tokens: result.data!.tokens,
          isVerified: result.data!.isVerified);
      // Update state
      state = AsyncValue.data(
          AuthAuthenticated(result.data!.user, result.data!.isVerified));
    } else {
      ref.read(appErrorProvider.notifier).state = result.error;
      state = const AsyncValue.data(AuthUnauthenticated());
    }
  }

  void loginAsGuest(String username) async {
    if (state.isLoading || _isLoggedIn) return;
    state = const AsyncValue.loading();

    await ref
        .read(sessionStorageProvider)
        .saveSession(user: User.guest(username), isVerified: false);

    state = AsyncValue.data(AuthGuest(User.guest(username)));
  }

  void logout() async {
    ref.read(loggerProvider).f("Logging out!");

    await ref.read(sessionStorageProvider).clearSession();
    await ref.read(authServiceProvider).googleSignOut();
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

  Future<Result> refreshTokens([CancellationToken? cancellationToken]) async {
    if (state.value == null || !state.value!.isAuthenticated) {
      return Result.failureMessage(
          "Cannot refresh tokens when no user is logged in");
    }

    TokensDTO? tokens = ref.read(sessionStorageProvider).tokens;

    if (tokens == null) {
      return Result.failureMessage("Tokens are empty, cannot refresh them");
    }

    if (_refreshTokenCompleter != null) {
      await _refreshTokenCompleter?.future;
      // Right now second callers to this method will only wait for the first caller to finish refreshing the tokens
      // For all of them and it will return, but if it fails it will also return and the second callers wont know either.
      // TODO: Refactor this part
      return Result.success();
    }

    _refreshTokenCompleter = Completer();

    ref.read(loggerProvider).d("Refreshing tokens");
    Result<TokensDTO> result = await ref
        .read(authServiceProvider)
        .refreshAccessToken(
            tokens: tokens,
            onExpire: kickUser,
            cancellationToken: cancellationToken);

    if (!result.isSuccess) {
      if (!_refreshTokenCompleter!.isCompleted) {
        //TODO: Throw error for other callers

        // _refreshTokenCompleter?.completeError("failed to refresh tokens");
      }
    } else {
      await ref.read(sessionStorageProvider).updateTokens(
          accessToken: result.data!.accessToken,
          refreshToken: result.data!.refreshToken);
    }
    _refreshTokenCompleter!.complete();
    _refreshTokenCompleter = null;

    return result;
  }

  Future<Result> sendVerificationEmail() async {
    Result result = await ref.read(authServiceProvider).sendVerificationEmail();

    if (!result.isSuccess) {
      ref.read(appErrorProvider.notifier).state = result.error!;
    }

    return result;
  }

// TODO: When the user verifies, `updateVerificationStatus` gets called from server to update the UI immediately, however if the app is closed, it wont update so we need to check the status from the server on startup or unpausing the app
  void refetchVerificationStatus() async {
    // Only check if we are authenticated
    if (!state.hasValue || !state.value!.isAuthenticated) {
      return;
    }

    // If we aren't verified
    if (!state.value!.asAuthenticated!.isVerified) {
      // We check our verification status from the server
      Result<bool> result =
          await ref.read(authServiceProvider).checkVerificationStatus();

      // If theres an error, we display and return the error
      if (!result.isSuccess) {
        ref.read(appErrorProvider.notifier).state = result.error!;
        return;
      }
      // If the result is true
      if (result.data!) {
        // we update the verification status on our state
        state = AsyncValue.data(
            AuthAuthenticated(state.value!.asAuthenticated!.user, true));
      }
    }
  }

  void updateVerificationStatus(bool isVerified) async {
    // Only continue if we are authenticated
    if (!state.hasValue || !state.value!.isAuthenticated) {
      return;
    }
    state = AsyncValue.data(
        AuthAuthenticated(state.value!.asAuthenticated!.user, isVerified));
  }

  Future<Result> requestPasswordReset(String email) async {
    Result result =
        await ref.read(authServiceProvider).requestPasswordReset(email);

    if (!result.isSuccess) {
      ref.read(appErrorProvider.notifier).state = result.error!;
    }

    return result;
  }

  // Value can be null when we are loading or theres an error,
  // even tho i dont throw errors when it happens and instead capture it in an AppError provider,
  // edge cases can happen and the notifier automatically wraps the throws into an AsyncValue.error
  bool get _isLoggedIn {
    final value = state.valueOrNull;
    return value?.isAuthenticated == true || value?.isGuest == true;
  }

  Future<Session?> loadSession() async {
    return await ref.read(sessionStorageProvider).loadSession();
  }

  @override
  Future<AuthState> build() async {
    ref.read(loggerProvider).w("building auth notifier");

    Session? session = await loadSession();

    if (session == null) return const AuthUnauthenticated();

    if (session.user.id == -1) return AuthGuest(session.user);

    return AuthAuthenticated(session.user, session.isVerified);
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => AuthRepository(dio: ref.watch(dioProvider)));

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(authRepository: ref.watch(authRepositoryProvider));
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

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  ref.read(loggerProvider).d("Constructing session storage");
  return SessionStorage(
      secureStorage: ref.watch(secureStorageProvider),
      sharedPreferences: ref.watch(sharedPreferencesProvider),
      databaseManager: ref.watch(localDbProvider));
});

final isVerifiedProvider = Provider.autoDispose<bool>((ref) {
  AsyncValue<AuthState> authState = ref.watch(authNotifierProvider);

  if (authState.value == null || !authState.value!.isAuthenticated) {
    return false;
  }
  return authState.value!.asAuthenticated!.isVerified;
});

// A simple persistent countdown timer that counts from 0 to seconds and then completes
class ResetPasswordTimerNotifier extends Notifier<int?> {
  void startTimer(int seconds) {
    if (state != null) return;
    state = seconds;
    Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        state = state! - 1;

        if (state! <= 0) {
          timer.cancel();
          state = null;
        }
      },
    );
  }

  @override
  int? build() {
    return null;
  }
}

final resetPasswordTimerNotifierProvider =
    NotifierProvider<ResetPasswordTimerNotifier, int?>(
        ResetPasswordTimerNotifier.new);

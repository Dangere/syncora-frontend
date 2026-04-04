import 'dart:async';
import 'package:cancellation_token/cancellation_token.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_response_dto.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/models/google_register_filled_info.dart';
import 'package:syncora_frontend/features/authentication/models/google_user_info.dart';
import 'package:syncora_frontend/features/authentication/models/session.dart';
import 'package:syncora_frontend/features/authentication/models/tokens.dart';
import 'package:syncora_frontend/features/users/models/user.dart';
import 'package:syncora_frontend/features/authentication/auth_repository.dart';
import 'package:syncora_frontend/features/authentication/services/auth_service.dart';
import 'package:syncora_frontend/features/authentication/services/session_storage.dart';
import 'package:syncora_frontend/features/users/models/user_preferences.dart';
import 'package:syncora_frontend/features/users/providers/users_provider.dart';

// TODO: Implement guard for connection checking before methods

class AuthNotifier extends AsyncNotifier<AuthState> {
  Completer? _refreshTokenCompleter;

  void loginUsingGoogle() async {
    if (state.isLoading || _isLoggedIn) return;

    state = const AsyncValue.loading();

    Result<AuthResponseDTO> result =
        await ref.read(authServiceProvider).loginWithGoogle();

    if (result.isCancelled) {
      state = const AsyncValue.data(AuthUnauthenticated());
      return;
    }

    if (!result.isSuccess) {
      ref.read(appErrorProvider.notifier).state = result.error!;
      state = const AsyncValue.data(AuthUnauthenticated());
      return;
    }

    // Save session and user data
    Result saveSessionResult = await _saveSession(
        result.data!.user,
        result.data!.isVerified,
        result.data!.tokens,
        result.data!.userPreferences);

    if (!saveSessionResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = saveSessionResult.error!;
      state = const AsyncValue.data(AuthUnauthenticated());
      return;
    }

    // Update state
    state = AsyncValue.data(
        AuthAuthenticated(result.data!.user.id, result.data!.isVerified));
  }

  /// Displays a pop up that allows the user to select a google account and returns the token with info
  Future<Result<GoogleUserInfo>> getGoogleRegisterToken() async {
    if (_isLoggedIn) {
      return Result.canceled("User is logged in");
    }
    if (state.isLoading) return Result.canceled("Already loading");

    state = const AsyncValue.loading();

    Result<GoogleUserInfo> result =
        await ref.read(authServiceProvider).getGoogleRegisterToken();

    if (result.isCancelled) {
      state = const AsyncValue.data(AuthUnauthenticated());
      return result;
    }

    if (!result.isSuccess) {
      ref.read(appErrorProvider.notifier).state = result.error!;
    }
    state = const AsyncValue.data(AuthUnauthenticated());
    return result;
  }

  /// Uses a preselected GoogleUserInfo and user selected GoogleRegisterFilledInfo to register
  void registerUsingGoogle(GoogleUserInfo googleUserInfo,
      GoogleRegisterFilledInfo userFilledInfo) async {
    if (state.isLoading || _isLoggedIn) return;

    state = const AsyncValue.loading();

    Result<AuthResponseDTO> result = await ref
        .read(authServiceProvider)
        .registerUserWithGoogle(googleUserInfo, userFilledInfo);

    if (!result.isSuccess) {
      ref.read(appErrorProvider.notifier).state = result.error!;
      state = const AsyncValue.data(AuthUnauthenticated());

      return;
    }

    // Save session and user data
    Result saveSessionResult = await _saveSession(
        result.data!.user,
        result.data!.isVerified,
        result.data!.tokens,
        result.data!.userPreferences);

    if (!saveSessionResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = saveSessionResult.error!;
      state = const AsyncValue.data(AuthUnauthenticated());
      return;
    }

    // Update state
    state = AsyncValue.data(
        AuthAuthenticated(result.data!.user.id, result.data!.isVerified));
  }

  void loginWithEmailAndPassword(
      {required String email, required String password}) async {
    if (state.isLoading || _isLoggedIn) return;

    state = const AsyncValue.loading();

    Result<AuthResponseDTO> result = await ref
        .read(authServiceProvider)
        .loginWithEmailAndPassword(email: email, password: password);

    if (!result.isSuccess) {
      ref.read(appErrorProvider.notifier).state = result.error!;
      state = const AsyncValue.data(AuthUnauthenticated());
    }

    // Save session and user data
    Result saveSessionResult = await _saveSession(
        result.data!.user,
        result.data!.isVerified,
        result.data!.tokens,
        result.data!.userPreferences);

    if (!saveSessionResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = saveSessionResult.error!;
      state = const AsyncValue.data(AuthUnauthenticated());
      return;
    }

    // Update state
    state = AsyncValue.data(
        AuthAuthenticated(result.data!.user.id, result.data!.isVerified));
  }

  void registerWithEmailAndPassword(
      {required String email,
      required String username,
      required String firstName,
      required String lastName,
      required String password}) async {
    if (state.isLoading || _isLoggedIn) return;

    state = const AsyncValue.loading();

    Result<AuthResponseDTO> result = await ref
        .read(authServiceProvider)
        .registerWithEmailAndPassword(
            email: email,
            username: username,
            password: password,
            firstName: firstName,
            lastName: lastName);

    if (!result.isSuccess) {
      ref.read(appErrorProvider.notifier).state = result.error!;
      state = const AsyncValue.data(AuthUnauthenticated());

      return;
    }

    // Save session and user data
    Result saveSessionResult = await _saveSession(
        result.data!.user,
        result.data!.isVerified,
        result.data!.tokens,
        result.data!.userPreferences);

    if (!saveSessionResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = saveSessionResult.error!;
      state = const AsyncValue.data(AuthUnauthenticated());
      return;
    }

    // Update state
    state = AsyncValue.data(
        AuthAuthenticated(result.data!.user.id, result.data!.isVerified));
  }

  void loginAsGuest(String username) async {
    if (state.isLoading || _isLoggedIn) return;
    state = const AsyncValue.loading();

    // Save session and user data
    Result saveSessionResult = await _saveSession(
        User.guest(username), false, null, UserPreferences.defaults());

    if (!saveSessionResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state = saveSessionResult.error!;
      state = const AsyncValue.data(AuthUnauthenticated());
      return;
    }

    state = const AsyncValue.data(AuthGuest());
  }

  void logout() async {
    ref.read(loggerProvider).f("Logging out!");

    // TODO: This should tell the user if theres unsynced data that will be lost/deleted if they log out

    await ref.read(sessionStorageProvider).clearSession();
    await ref.read(authServiceProvider).googleSignOut();
    await ref.read(cacheManagerProvider).emptyCache();
    state = const AsyncValue.data(AuthUnauthenticated());
  }

  void kickUser() async {
    logout();

    // TODO: Show pop up instead of snackbar
    // TODO: in the future make it so you can differentiate between a revoked refresh token or an expired, and give different messages
    ref.read(appErrorProvider.notifier).state = AppError(
        message:
            "Your session was either expired or revoked, please login again",
        stackTrace: StackTrace.current);
  }

  Future<Result> refreshTokens([CancellationToken? cancellationToken]) async {
    if (state.value?.isAuthenticated ?? false) {
      return Result.canceled("Cannot refresh tokens when no user is logged in");
    }

    Tokens? tokens = ref.read(sessionStorageProvider).tokens;

    if (tokens == null) {
      return Result.canceled("Tokens are empty, cannot refresh them");
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
    ref.read(loggerProvider).d(state.value?.isAuthenticated);

    Result<Tokens> result = await ref
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
      ref.read(loggerProvider).d("Tokens refreshed");
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
            AuthAuthenticated(state.value!.asAuthenticated!.userId, true));
      }
    }
  }

  void updateVerificationStatus(bool isVerified) async {
    // Only continue if we are authenticated
    if (!state.hasValue || !state.value!.isAuthenticated) {
      return;
    }
    state = AsyncValue.data(
        AuthAuthenticated(state.value!.asAuthenticated!.userId, isVerified));
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

  Future<Result<void>> _saveSession(User user, bool isVerified, Tokens? tokens,
      UserPreferences userPreferences) async {
    // Save data
    Result<void> saveUserResult =
        await ref.read(usersServiceProvider).saveUser(user);
    if (!saveUserResult.isSuccess) return saveUserResult;

    Result<void> saveUserPreferencesResult =
        await ref.read(usersServiceProvider).savePreferences(userPreferences);
    if (!saveUserPreferencesResult.isSuccess) return saveUserPreferencesResult;

    // Save session
    Result<void> saveSessionResult = await ref
        .read(sessionStorageProvider)
        .saveSession(userId: user.id, tokens: tokens, isVerified: isVerified);

    if (!saveSessionResult.isSuccess) return saveSessionResult;

    return Result.success();
  }

  @override
  Future<AuthState> build() async {
    ref.read(loggerProvider).w("building auth notifier");

    Result<Session?> session =
        await ref.read(sessionStorageProvider).loadSession();
    if (!session.isSuccess) {
      ref.read(appErrorProvider.notifier).state = session.error!;
      return const AuthUnauthenticated();
    }

    if (session.data == null) return const AuthUnauthenticated();

    if (session.data!.userId == -1) return const AuthGuest();

    return AuthAuthenticated(session.data!.userId, session.data!.isVerified);
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => AuthRepository(dio: ref.watch(dioProvider)));

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(authRepository: ref.watch(authRepositoryProvider));
});

final authStateProvider = Provider.autoDispose<AuthState>((ref) {
  var authState = ref.watch(authProvider);
  if (authState.asData != null) {
    return authState.value!;
  }

  return const AuthUnauthenticated();
});

final isLoggedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider.select((authState) {
    if (authState.value == null) return false;

    return authState.value!.isAuthenticated || authState.value!.isGuest;
  }));
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider.select((authState) {
    if (authState.value == null) return false;

    return authState.value!.isAuthenticated;
  }));
});

final isGuestProvider = Provider<bool>((ref) {
  return ref.watch(authProvider.select((authState) {
    if (authState.value == null) return true;

    return authState.value!.isGuest;
  }));
});

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  ref.read(loggerProvider).d("Constructing session storage");
  return SessionStorage(
    ref.watch(secureStorageProvider),
    ref.watch(sharedPreferencesProvider),
    ref.watch(localDbProvider),
  );
});

final isVerifiedProvider = Provider.autoDispose<bool>((ref) {
  AsyncValue<AuthState> authState = ref.watch(authProvider);

  if (authState.value == null || !authState.value!.isAuthenticated) {
    return false;
  }
  return authState.value!.asAuthenticated!.isVerified;
});

// A simple persistent countdown timer that counts from seconds to 0 and then completes to null
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

final resetPasswordTimerProvider =
    NotifierProvider<ResetPasswordTimerNotifier, int?>(
        ResetPasswordTimerNotifier.new);

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncora_frontend/common/interceptors/auth_interceptor.dart';
import 'package:syncora_frontend/common/interceptors/breadcrumb_interceptor.dart';
import 'package:syncora_frontend/common/interceptors/connection_interceptor.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/core/analytics/diagnostics_service.dart';
import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/core/error_management/error_provider.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/users/models/user_preferences.dart';
import 'package:syncora_frontend/features/users/providers/users_provider.dart';

/// Logger provider used to initialize the logger
final loggerProvider = Provider<Logger>((ref) {
  return Logger(
    printer: PrettyPrinter(
      methodCount: 0, // Number of method calls to be displayed
      // errorMethodCount: 0, // Number of method calls if stacktrace is provided
      lineLength: 40, // Width of the output (minimal)
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
      // noBoxingByDefault: true, // THIS removes the rounded borders/lines
    ),
  );
});

/// This is the authenticated dio instance, we make separate instances when we need to make unauthenticated requests
final dioProvider = Provider<Dio>((ref) {
  Dio dio = Dio();
  dio.options.headers['Device-Id'] =
      ref.read(diagnosticsServiceProvider).deviceId;

  dio.interceptors.add(BreadcrumbInterceptor());
  dio.interceptors.add(ConnectionInterceptor(() => ref.read(isOnlineProvider)));
  dio.interceptors.add(AuthInterceptor(
      tokensFactory: () => ref.read(sessionStorageProvider).tokens,
      refreshTokens: () async =>
          ref.read(authProvider.notifier).refreshTokens(),
      dio: dio));

  return dio;
});

/// This is the unauthenticated dio instance used in token refresh
final unauthenticatedDioProvider = Provider<Dio>((ref) {
  Dio dio = Dio();
  dio.options.headers['Device-Id'] =
      ref.read(diagnosticsServiceProvider).deviceId;

  dio.interceptors.add(BreadcrumbInterceptor());
  dio.interceptors.add(ConnectionInterceptor(() => ref.read(isOnlineProvider)));

  return dio;
});

/// Cache manager used to cache images locally
final cacheManagerProvider = Provider<CacheManager>((ref) {
  return DefaultCacheManager();
});

/// Image picker
final imagePickerProvider = Provider<ImagePicker>((ref) {
  return ImagePicker();
});

/// Secure storage
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Shared preferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  Logger().d("This shouldn't be reached and instead initialized in main()");
  // Gets initialized at main()
  throw UnimplementedError();
});

// final localeProvider = Provider<Locale>((ref) => const Locale('en'));

/// Locale provider used to get and set the locale
class LocaleNotifier extends Notifier<Locale> {
  /// Sets the locale
  void setLocale(Locale locale) async {
    state = locale;

    Result result = await ref
        .read(usersServiceProvider)
        .updatePreferences(languageCode: state.languageCode);

    if (!result.isSuccess && !result.isCancelled) {
      ref.read(appErrorProvider.notifier).setError(result.error!);
    }
  }

  /// Toggles the locale between en and ar
  void toggleLocale() async {
    if (state.languageCode == 'en') {
      state = const Locale('ar');
    } else {
      state = const Locale('en');
    }

    Result result = await ref
        .read(usersServiceProvider)
        .updatePreferences(languageCode: state.languageCode);

    if (!result.isSuccess && !result.isCancelled) {
      ref.read(appErrorProvider.notifier).setError(result.error!);
    }
  }

  /// Returns the text direction
  TextDirection getTextDirection() {
    return intl.Bidi.isRtlLanguage(state.languageCode)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  @override
  Locale build() {
    // Listens to auth state to update the locale when the user logs in
    ref.listen(
      authStateProvider,
      (previous, next) {
        Result<UserPreferences> preferences =
            ref.read(usersServiceProvider).getPreferences();

        if (preferences.isSuccess) {
          state = preferences.data!.locale;
        }
      },
    );
    // Try to get the locale from shared preferences
    Result<UserPreferences> preferences =
        ref.read(usersServiceProvider).getPreferences();

    if (!preferences.isSuccess) {
      ref.read(appErrorProvider.notifier).setError(preferences.error!);
    }

    return preferences.isSuccess
        ? preferences.data!.locale
        : const Locale('en');
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

/// Theme mode provider used to get and set the theme mode
class ThemeModeNotifier extends Notifier<ThemeMode> {
  /// sets the theme mode
  void setThemDark(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;

    Result result = await ref
        .read(usersServiceProvider)
        .updatePreferences(darkMode: state == ThemeMode.dark);

    if (!result.isSuccess && !result.isCancelled) {
      ref.read(appErrorProvider.notifier).setError(result.error!);
    }
  }

  @override
  ThemeMode build() {
    // Listens to auth state to update the theme mode when the user logs in
    ref.listen(
      authStateProvider,
      (previous, next) {
        Result<UserPreferences> preferences =
            ref.read(usersServiceProvider).getPreferences();

        if (preferences.isSuccess) {
          state = preferences.data!.darkMode ? ThemeMode.dark : ThemeMode.light;
        }
      },
    );
    // Try to get the theme mode from shared preferences
    Result<UserPreferences> preferences =
        ref.read(usersServiceProvider).getPreferences();

    if (!preferences.isSuccess) {
      ref.read(appErrorProvider.notifier).setError(preferences.error!);
    }

    return preferences.isSuccess
        ? preferences.data!.darkMode
            ? ThemeMode.dark
            : ThemeMode.light
        : ThemeMode.light;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Database manager provider
final localDbProvider = Provider<DatabaseManager>((ref) {
  ref.read(loggerProvider).d("Constructing database manager");

  return DatabaseManager(logger: ref.read(loggerProvider));
});

/// A family provider used to store a list of previous search history in memory
class SearchBarSuggestionsNotifier
    extends FamilyNotifier<List<String>, String> {
  void addSuggestion(String suggestion) {
    state.remove(suggestion);
    state = [suggestion, ...state];
  }

  @override
  List<String> build(String id) {
    return [];
  }
}

final searchBarSuggestionsProvider =
    NotifierProvider.family<SearchBarSuggestionsNotifier, List<String>, String>(
        SearchBarSuggestionsNotifier.new);

/// A provider used to get the diagnostics service
final diagnosticsServiceProvider = Provider<DiagnosticsService>((ref) {
  return DiagnosticsService(
    languageCode: () => ref.read(localeProvider).languageCode,
  );
});

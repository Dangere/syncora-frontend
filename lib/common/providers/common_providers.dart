import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncora_frontend/common/interceptors/auth_interceptor.dart';
import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';

final loggerProvider = Provider<Logger>((ref) {
  return Logger(
    printer: PrettyPrinter(
      methodCount: 0, // Number of method calls to be displayed
      errorMethodCount: 0, // Number of method calls if stacktrace is provided
      lineLength: 40, // Width of the output (minimal)
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
      // noBoxingByDefault: true, // THIS removes the rounded borders/lines
    ),
  );
});

final dioProvider = Provider<Dio>((ref) {
  Dio dio = Dio();
  dio.interceptors.add(AuthInterceptor(
      sessionStorage: ref.read(sessionStorageProvider),
      refreshTokens: () async =>
          ref.read(authProvider.notifier).refreshTokens(),
      dio: dio));

  return dio;
});

final cacheManagerProvider = Provider<CacheManager>((ref) {
  return DefaultCacheManager();
});

final imagePickerProvider = Provider<ImagePicker>((ref) {
  return ImagePicker();
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  Logger().d("This shouldn't be reached and instead initialized in main()");
  // Gets initialized at main()
  throw UnimplementedError();
});

// final localeProvider = Provider<Locale>((ref) => const Locale('en'));

class LocaleNotifier extends Notifier<Locale> {
  void setLocale(Locale locale) {
    state = locale;
  }

  void toggleLocale() {
    if (state.languageCode == 'en') {
      state = const Locale('ar');
    } else {
      state = const Locale('en');
    }
  }

  @override
  Locale build() {
    return const Locale('en');
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  void setThemDark(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  ThemeMode build() {
    return ThemeMode.light;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// TODO: Refactor this into a notifier that fires events at the root screen to display errors
final appErrorProvider = StateProvider<AppError?>((ref) {
  return null;
});
final localDbProvider = Provider<DatabaseManager>((ref) {
  ref.read(loggerProvider).d("Constructing database manager");

  return DatabaseManager(logger: ref.read(loggerProvider));
});

class SearchBarSuggestionsNotifier extends Notifier<List<String>> {
  void addSuggestion(String suggestion) {
    state.remove(suggestion);
    state = [suggestion, ...state];
  }

  @override
  List<String> build() {
    return [];
  }
}

final searchBarSuggestionsProvider =
    NotifierProvider<SearchBarSuggestionsNotifier, List<String>>(
        SearchBarSuggestionsNotifier.new);

// final localDbProvider = Provider<DatabaseManager>((ref) {
//   bool isGuest = ref.watch(isGuestProvider);
//   ref.read(loggerProvider).w(isGuest);
//   if (isGuest) {
//     return DatabaseManager(target: DatabaseTarget.guest);
//   }
//   return DatabaseManager(target: DatabaseTarget.user);
// });

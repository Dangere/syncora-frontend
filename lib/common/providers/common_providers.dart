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
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/users/models/user_preferences.dart';
import 'package:syncora_frontend/features/users/providers/users_provider.dart';

final loggerProvider = Provider<Logger>((ref) {
  return Logger(
    printer: PrettyPrinter(
      // methodCount: 0, // Number of method calls to be displayed
      // errorMethodCount: 0, // Number of method calls if stacktrace is provided
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
      tokensFactory: () => ref.read(sessionStorageProvider).tokens,
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
  void setLocale(Locale locale) async {
    state = locale;

    Result result = await ref
        .read(usersServiceProvider)
        .updatePreferences(languageCode: state.languageCode);

    if (!result.isSuccess && !result.isCancelled) {
      ref.read(appErrorProvider.notifier).state = result.error;
    }
  }

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
      ref.read(appErrorProvider.notifier).state = result.error;
    }
  }

  @override
  Locale build() {
    ref.listen(
      authStateProvider,
      (previous, next) async {
        // if (next) {
        Result<UserPreferences> preferences =
            await ref.read(usersServiceProvider).getPreferences();

        if (preferences.isSuccess) {
          state = preferences.data!.locale;
        }
      },
    );

    return const Locale('en');
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  void setThemDark(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;

    Result result = await ref
        .read(usersServiceProvider)
        .updatePreferences(darkMode: state == ThemeMode.dark);

    if (!result.isSuccess && !result.isCancelled) {
      ref.read(appErrorProvider.notifier).state = result.error;
    }
  }

  @override
  ThemeMode build() {
    ref.listen(
      authStateProvider,
      (previous, next) async {
        Result<UserPreferences> preferences =
            await ref.read(usersServiceProvider).getPreferences();

        if (preferences.isSuccess) {
          state = preferences.data!.darkMode ? ThemeMode.dark : ThemeMode.light;
        }
      },
    );
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

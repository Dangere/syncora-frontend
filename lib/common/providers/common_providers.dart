import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncora_frontend/common/interceptors/auth_interceptor.dart';
import 'package:syncora_frontend/common/themes/app_theme.dart';
import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';

final loggerProvider = Provider<Logger>((ref) {
  return Logger();
});

final dioProvider = Provider<Dio>((ref) {
  Dio dio = Dio();
  dio.interceptors.add(AuthInterceptor(
      sessionStorage: ref.read(sessionStorageProvider), ref: ref, dio: dio));

  return dio;
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  Logger().d("This shouldn't be reached and instead initialized in main()");
  // Gets initialized at main()
  throw UnimplementedError();
});

final themeProvider = Provider<ThemeData>((ref) {
  return AppTheme.appLightTheme;
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

final localeNotifierProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

final appErrorProvider = StateProvider<AppError?>((ref) {
  return null;
});
final localDbProvider = Provider<DatabaseManager>((ref) {
  ref.read(loggerProvider).d("Constructing database manager");

  return DatabaseManager();
});

// final localDbProvider = Provider<DatabaseManager>((ref) {
//   bool isGuest = ref.watch(isGuestProvider);
//   ref.read(loggerProvider).w(isGuest);
//   if (isGuest) {
//     return DatabaseManager(target: DatabaseTarget.guest);
//   }
//   return DatabaseManager(target: DatabaseTarget.user);
// });

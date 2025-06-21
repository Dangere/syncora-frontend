import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncora_frontend/common/interceptors/auth_interceptor.dart';
import 'package:syncora_frontend/common/themes/app_theme.dart';
import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/core/data/enums/database_target.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';

final loggerProvider = Provider<Logger>((ref) {
  return Logger();
});

final dioProvider = Provider<Dio>((ref) {
  Dio dio = Dio();
  dio.interceptors
      .add(AuthInterceptor(sessionStorage: ref.read(sessionStorageProvider)));

  return dio;
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  // Gets initialized at main()
  throw UnimplementedError();
});

final themeProvider = Provider<ThemeData>((ref) {
  return AppTheme.appLightTheme;
});

final localeProvider = Provider<Locale>((ref) => const Locale('en'));

final appErrorProvider = StateProvider<AppError?>((ref) {
  return null;
});

final localDbProvider = Provider.autoDispose<DatabaseManager>((ref) {
  bool isGuest = ref.watch(isGuestProvider);
  if (isGuest) {
    return DatabaseManager(target: DatabaseTarget.guest);
  }
  return DatabaseManager(target: DatabaseTarget.user);
});

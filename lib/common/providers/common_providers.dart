import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncora_frontend/common/themes/app_theme.dart';

final loggerProvider = Provider<Logger>((ref) {
  return Logger();
});

final dioProvider = Provider<Dio>((ref) => Dio());

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

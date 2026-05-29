import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_theme.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/debug/breadcrumb_log.dart';
import 'package:syncora_frontend/router.dart';

void main() async {
  // Initializing binding immediately to ensure any dart code that relies on platform channels
  // can run properly on start up such as shared preferences and flutter secure storage
  WidgetsFlutterBinding.ensureInitialized();

  runApp(ProviderScope(
      overrides: await providerOverrides(),
      child: DevicePreview(
          enabled: !kReleaseMode, builder: (context) => const MyApp())));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    GoRouter router = ref.watch(routeProvider);
    ThemeMode themeMode = ref.watch(themeModeProvider);
    Locale locale = ref.watch(localeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      locale: locale,
      builder: (context, child) {
        return Directionality(
          textDirection: ref.read(localeProvider.notifier).getTextDirection(),
          child: Stack(
            children: [
              DevicePreview.appBuilder(context, child),
              // if (kDebugMode) const BreadcrumbLog()
            ],
          ),
        );
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      title: 'Syncora',
      themeMode: themeMode,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
    );
  }
}

Future<List<Override>> providerOverrides() async {
  final sharedPreferences = await SharedPreferences.getInstance();

  return [sharedPreferencesProvider.overrideWith((ref) => sharedPreferences)];
}

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
import 'package:syncora_frontend/core/network/syncing/sync_viewmodel.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
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
    // ThemeData theme = AppTheme.appLightTheme;
    // Locale locale = ref.watch(localeProvider);
    // Initialize sync notifier
    // registerSyncListeners(ref);

    return MaterialApp.router(
      useInheritedMediaQuery: true,
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      // locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      title: 'Syncora',
      theme: AppTheme.appLightTheme,
      darkTheme: AppTheme.appDarkTheme,
    );
  }
}

Future<List<Override>> providerOverrides() async {
  final sharedPreferences = await SharedPreferences.getInstance();

  return [sharedPreferencesProvider.overrideWith((ref) => sharedPreferences)];
}

// void registerSyncListeners(WidgetRef ref) {
//   ref.listen(isAuthenticatedProvider, (previous, next) {
//     if (next) {
//       if (ref.exists(syncBackendNotifierProvider)) {
//         ref.read(syncBackendNotifierProvider.notifier).initializeConnection();
//       }
//       ref.read(syncBackendNotifierProvider.notifier);

//       // ref.read(syncBackendNotifierProvider.notifier);
//     } else {
//       ref.read(syncBackendNotifierProvider.notifier).dispose();
//     }
//   });
// }

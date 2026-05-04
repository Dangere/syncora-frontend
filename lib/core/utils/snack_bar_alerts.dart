import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/network/syncing/sync_provider.dart';

class SnackBarAlerts {
  static bool _initialized = false;
  static void showSnackBar(String message, BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  static void showSuccessSnackBar(String message, BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

  static void showErrorSnackBar(String message, BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  static void showAlertSnackBar(String message, BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.yellowAccent.shade400,
    ));
  }

  /// Registers a listener to the error message provider
  /// and shows an error snackbar when the error message is not null
  static void registerNotificationListener(
      WidgetRef ref, BuildContext context) {
    if (!context.mounted) return;

    // Listening for errors
    ref.listen(appErrorProvider, (previous, next) {
      // Check if the current page is the top page
      bool isTopPage = ModalRoute.of(context)?.isCurrent ?? false;
      if (next != null && isTopPage) {
        String localizedErrorMessage = ref
            .read(localizeAppErrorsProvider)
            .localizeErrorCode(next.errorCode, context);

        showErrorSnackBar(localizedErrorMessage, context);
        Future.microtask(() {
          ref.read(appErrorProvider.notifier).state = null;
        });
        ref.read(loggerProvider).e("${next.logMessage}\n");
      }
    });

    // // Listening for online status
    // ref.listen(appErrorProvider, (previous, next) {
    //   // Check if the current page is the top page
    //   bool isTopPage = ModalRoute.of(context)?.isCurrent ?? false;
    //   if (next != null && isTopPage) {
    //     String localizedErrorMessage = ref
    //         .read(localizeAppErrorsProvider)
    //         .localizeErrorCode(next.errorCode, context);

    //     showErrorSnackBar(localizedErrorMessage, context);
    //     Future.microtask(() {
    //       ref.read(appErrorProvider.notifier).state = null;
    //     });
    //     ref.read(loggerProvider).e("${next.logMessage}\n");
    //   }
    // });

    // Listening for backend availability
    ref.read(signalRClientProvider).onStateChanged.listen((event) {
      switch (event) {
        case HubConnectionState.Connected:
          if (context.mounted && !_initialized) {
            showSuccessSnackBar(
                AppLocalizations.of(context).notification_Backend_Connected,
                context);
            _initialized = true;
          }
          break;
        case HubConnectionState.Disconnected:
          // showErrorSnackBar("Disconnected from server", context);
          break;
        case HubConnectionState.Connecting:
          // showSnackBar("Connecting to server", context);

          break;

        case HubConnectionState.Reconnecting:
          // showSnackBar("Reconnecting to server", context);

          break;

        case HubConnectionState.Disconnecting:
          // showAlertSnackBar("Disconnecting from server", context);

          break;
      }
    });
    // Listening for internet connectivity

    ref.listen(isOnlineProvider, (previous, next) {
      if (next && context.mounted) {
        showSuccessSnackBar(
            AppLocalizations.of(context).notification_Online_Connected,
            context);
      } else if (!next && context.mounted) {
        showAlertSnackBar(
            AppLocalizations.of(context).notification_Online_Disconnected,
            context);
      }
    });
  }
}

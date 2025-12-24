import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';

class SnackBarAlerts {
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

  /// Registers a listener to the error message provider
  /// and shows an error snackbar when the error message is not null
  static void registerErrorListener(WidgetRef ref, BuildContext context) {
    if (!context.mounted) return;

    ref.listen(appErrorProvider, (previous, next) {
      // Check if the current page is the top page
      bool isTopPage = ModalRoute.of(context)?.isCurrent ?? false;
      if (next != null && isTopPage) {
        showErrorSnackBar(next.message, context);
        Future.microtask(() {
          ref.read(appErrorProvider.notifier).state = null;
        });
        ref
            .read(loggerProvider)
            .e("${next.message}\nError Source: ${context.widget.runtimeType}");
        if (next.stackTrace != null) {
          ref.read(loggerProvider).w(next.stackTrace);
        }
      }
    });
  }
}

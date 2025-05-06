import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';

class SnackBarAlerts {
  static void showSnackBar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  static void showSuccessSnackBar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

  static void showErrorSnackBar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  /// Registers a listener to the error message provider
  /// and shows an error snackbar when the error message is not null
  static void registerErrorListener(WidgetRef ref, BuildContext context) {
    ref.listen(appErrorProvider, (previous, next) {
      if (next != null) {
        showErrorSnackBar(next.message, context);
        ref.read(appErrorProvider.notifier).state = null;
        ref.read(loggerProvider).e(next.message);
        if (next.parsedStackTrace != null) {
          ref.read(loggerProvider).w(next.parsedStackTrace);
        }
      }
    });
  }
}

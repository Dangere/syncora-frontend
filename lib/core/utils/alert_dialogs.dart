import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:syncora_frontend/core/typedef.dart';

class AlertDialogs {
  static void showTextFieldDialog(context,
      {required bool barrierDismissible,
      required bool blurBackground,
      required String message,
      required Function(String) onContinue,
      required Func<String, String?> validation}) {
    TextEditingController textEditingController = TextEditingController();
    showDialog(
      barrierDismissible: barrierDismissible,
      context: context,
      builder: (context) {
        double blurAmount = blurBackground ? 10 : 0;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: PopScope(
            canPop: true,
            child: AlertDialog(
              actionsAlignment: MainAxisAlignment.spaceBetween,
              // actionsOverflowAlignment: OverflowBarAlignment.center,
              actionsPadding: const EdgeInsets.all(15),
              title: Text(message),
              content: TextField(
                controller: textEditingController,
                autofocus: true,
              ),
              // actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel")),
                ElevatedButton(
                  child: const Text("Continue"),
                  onPressed: () {
                    if (validation(textEditingController.text.trim()) != null) {
                      return;
                    }

                    onContinue(textEditingController.text.trim());
                    Navigator.of(context).pop();
                  },
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

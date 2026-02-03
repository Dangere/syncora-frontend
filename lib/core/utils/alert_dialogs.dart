import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:syncora_frontend/core/typedef.dart';

class AlertDialogs {
  static void simpleDialog(context,
      {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          content: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          actions: [
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Ok"))
          ],
        );
      },
    );
  }

  static void actionsDialog(context,
      {required String title,
      required String message,
      required List<DialogAction> actions}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // actionsOverflowAlignment: OverflowBarAlignment.center,
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          content: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall,
          ),

          actions: List.generate(actions.length, (index) {
            return ElevatedButton(
                onPressed: actions[index].onClick,
                child: Text(actions[index].title));
          }),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.all(15),
        );
      },
    );
  }

  static Future showTextFieldDialog(context,
      {required bool barrierDismissible,
      required bool blurBackground,
      required String message,
      required Function(String) onContinue,
      required Func<String, String?> validation,
      String? defaultText,
      String? defaultHintText}) {
    TextEditingController textEditingController =
        TextEditingController(text: defaultText);

    String? invalidationMessage;

    return showDialog(
      barrierDismissible: barrierDismissible,
      context: context,
      builder: (context) {
        double blurAmount = blurBackground ? 10 : 0;
        return StatefulBuilder(builder: (context, setState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
            child: AlertDialog(
              actionsAlignment: MainAxisAlignment.spaceBetween,
              // actionsOverflowAlignment: OverflowBarAlignment.center,
              actionsPadding: const EdgeInsets.all(15),
              title: Text(message),
              content: TextField(
                controller: textEditingController,
                autofocus: true,
                decoration: InputDecoration(
                    hintText: defaultHintText ?? "Enter text here",
                    errorText: invalidationMessage),
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
                    setState(() {});
                    invalidationMessage =
                        validation(textEditingController.text.trim());
                    if (invalidationMessage != null) {
                      return;
                    }

                    Navigator.of(context).pop();
                    onContinue(textEditingController.text.trim());
                  },
                )
              ],
            ),
          );
        });
      },
    );
  }
}

class DialogAction {
  final String title;
  final VoidCallback onClick;

  DialogAction({required this.onClick, required this.title});

  factory DialogAction.closeAction(context) {
    return DialogAction(
        onClick: () {
          Navigator.of(context).pop();
        },
        title: "Cancel");
  }
}

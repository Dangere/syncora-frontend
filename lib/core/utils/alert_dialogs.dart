import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/input_field.dart';
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

  // This can be called and will stay on screen until its dismissed
  static Future showContentTextFieldDialog(
    context, {
    required bool barrierDismissible,
    required bool blurBackground,
    required String message,
    required Func<String?, String?> validation,
    required Widget Function(
            String Function() fieldValue, bool Function() validateValue)
        content,
    String? label,
    String? defaultText,
    String? defaultHintText,
  }) async {
    TextEditingController textEditingController =
        TextEditingController(text: defaultText);

    final fieldKey = GlobalKey<FormFieldState>();

    return showDialog(
      barrierDismissible: barrierDismissible,
      context: context,
      builder: (context) {
        double blurAmount = blurBackground ? 10 : 0;
        return StatefulBuilder(builder: (context, setState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
            child: AlertDialog(
              contentPadding: const EdgeInsets.all(0),
              content: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(child: SizedBox()),
                          Expanded(
                            flex: 5,
                            child: Text(
                              message,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                              child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              size: 24,
                              Icons.close,
                            ),
                          ))
                        ],
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      InputField(
                          fieldKey: fieldKey,
                          controller: textEditingController,
                          validator: validation,
                          labelText: label ?? "",
                          hintText: defaultHintText ?? "",
                          keyboardType: TextInputType.none),
                      const SizedBox(
                        height: 24,
                      ),
                      content(
                        () => textEditingController.text,
                        () => fieldKey.currentState?.validate() ?? false,
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  // This is meant to be called and awaited for a single result
  static Future<String?> showTextFieldDialog(context,
      {required bool barrierDismissible,
      required bool blurBackground,
      required String message,
      required Func<String?, String?> validation,
      String? label,
      String? defaultText,
      String? defaultHintText}) async {
    TextEditingController textEditingController =
        TextEditingController(text: defaultText);
    final fieldKey = GlobalKey<FormFieldState>();

    return showDialog<String?>(
      barrierDismissible: barrierDismissible,
      context: context,
      builder: (context) {
        double blurAmount = blurBackground ? 10 : 0;
        return StatefulBuilder(builder: (context, setState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
            child: AlertDialog(
              contentPadding: const EdgeInsets.all(0),
              content: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TITLE AND CLOSE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(child: SizedBox()),
                          Expanded(
                            flex: 5,
                            child: Text(
                              message,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                              child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              size: 24,
                              Icons.close,
                            ),
                          ))
                        ],
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      // TEXT FIELD
                      InputField(
                          fieldKey: fieldKey,
                          controller: textEditingController,
                          validator: validation,
                          labelText: label ?? "",
                          hintText: defaultHintText ?? "",
                          keyboardType: TextInputType.none),
                      const SizedBox(
                        height: 24,
                      ),
                      // ADD BUTTON
                      AppButton(
                          size: AppButtonSize.small,
                          style: AppButtonStyle.filled,
                          intent: AppButtonIntent.primary,
                          onPressed: () {
                            if (fieldKey.currentState!.validate()) {
                              Navigator.of(context)
                                  .pop(textEditingController.text.trim());
                            }
                          },
                          child: const Text("Add"))
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }
}

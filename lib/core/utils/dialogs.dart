import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/input_field.dart';
import 'package:syncora_frontend/core/typedef.dart';

class DialogFieldData {
  final Func<String?, String?> validation;
  final String? label;
  final String? defaultHintText;
  final String? defaultText;
  final bool multiLine;
  final TextInputType keyboardType;
  final bool autofocus;

  DialogFieldData(
      {required this.validation,
      this.label,
      this.defaultHintText,
      this.defaultText,
      this.multiLine = false,
      this.keyboardType = TextInputType.text,
      this.autofocus = false});
}

class Dialogs {
  static Future<T?> showContentDialog<T>(context,
      {required bool barrierDismissible,
      required bool blurBackground,
      required String title,
      required Widget content,
      bool disableKeyboardAdjustment = false}) async {
    return await showDialog<T?>(
      barrierDismissible: barrierDismissible,
      context: context,
      builder: (context) {
        double blurAmount = blurBackground ? 10 : 0;
        return StatefulBuilder(builder: (context, setState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
            child: MediaQuery(
              data: MediaQuery.of(context).removeViewInsets(
                removeBottom: disableKeyboardAdjustment,
              ),
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
                                title,
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
                          height: 16,
                        ),

                        // CONTENT
                        content
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  static Future<bool> showConfirmationDialog(context,
      {required String message, required String confirmText}) async {
    bool? result = await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            contentPadding: const EdgeInsets.all(0),
            content: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // CLOSE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(child: SizedBox()),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            size: 24,
                            Icons.close,
                          ),
                        )
                      ],
                    ),

                    // TITLE
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            message,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    // CONFIRM BUTTON
                    AppButton(
                      size: AppButtonSize.mini,
                      style: AppButtonStyle.filled,
                      intent: AppButtonIntent.destructive,
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: Text(
                        confirmText,
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),

                    // CANCEL BUTTON
                    AppButton(
                      size: AppButtonSize.mini,
                      style: AppButtonStyle.outlined,
                      // intent: AppButtonIntent.secondary,
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        "Cancel",
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        });
      },
    );

    if (result != null) {
      return result;
    }

    return false;
  }

  static Future<List<String>> showTextFieldDialog(context,
      {required bool barrierDismissible,
      required bool blurBackground,
      required String title,
      required String confirmText,
      required List<DialogFieldData> fields}) async {
    if (fields.isEmpty) return [];

    List<TextEditingController> textControllers = List.generate(
      fields.length,
      (index) {
        return TextEditingController(text: fields[index].defaultText);
      },
    );

    final formKey = GlobalKey<FormState>();

    List<String>? dialog = await showDialog<List<String>>(
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
                              title,
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
                      Flexible(
                        child: Form(
                          key: formKey,
                          child: ListView.separated(
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                return InputField(
                                  controller: textControllers[index],
                                  validator: fields[index].validation,
                                  labelText: fields[index].label ?? "",
                                  hintText: fields[index].defaultHintText ?? "",
                                  multiline: fields[index].multiLine,
                                  keyboardType: fields[index].keyboardType,
                                  autoFocus: fields[index].autofocus,
                                );
                              },
                              separatorBuilder: (context, index) {
                                return const SizedBox(
                                  height: 24,
                                );
                              },
                              itemCount: fields.length),
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      // ADD BUTTON
                      AppButton(
                          size: AppButtonSize.small,
                          style: AppButtonStyle.filled,
                          intent: AppButtonIntent.primary,
                          fontSize: 20,
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.of(context).pop(List.generate(
                                textControllers.length,
                                (index) {
                                  return textControllers[index].text.trim();
                                },
                              ));
                            }
                          },
                          child: Text(confirmText))
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );

    if (dialog == null) return [];

    return dialog;
  }
}

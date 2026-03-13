import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/input_field.dart';
import 'package:syncora_frontend/common/widgets/profile_picture.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/core/utils/validators.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';

class DialogFieldData {
  final Func<String?, String?> validation;
  final String? label;
  final String? defaultHintText;
  final String? defaultText;
  final bool multiLine;

  DialogFieldData(
      {required this.validation,
      this.label,
      this.defaultHintText,
      this.defaultText,
      this.multiLine = false});
}

class AlertDialogs {
  static Future<T?> showContentDialog<T>(context,
      {required bool barrierDismissible,
      required bool blurBackground,
      required String title,
      required Widget content}) async {
    return await showDialog<T?>(
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
                        height: 16,
                      ),

                      // CONTENT
                      content
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

  static Future<bool> showConfirmationPopup(context,
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
                        child: Text(confirmText)),
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
                        child: const Text("Cancel"))
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

  static Future<List<User>?> selectUsersPopup(BuildContext context,
      {required Future<User?> Function(String username) findUser,
      required Future<List<User>> Function() currentUsers,
      required int ownerId}) async {
    List<User> users = [];
    TextEditingController textEditingController = TextEditingController();
    final fieldKey = GlobalKey<FormFieldState>();

    bool isLoading = false;

    Future onConfirm(
        String username, void Function(void Function()) setState) async {
      isLoading = true;
      // If the text field is empty, we confirm selection and return it
      if (textEditingController.text.isEmpty) {
        Navigator.of(context).pop(users);
        return;
      }

      // If the text field is not empty, we validate it
      if (!fieldKey.currentState!.validate()) return;

      List<User> members = await currentUsers();
      Logger().d(members.map((e) => e.username).toList());
      // If the user is the owner, we show a warning
      if (members.where((user) => user.username == username).firstOrNull?.id ==
          ownerId) {
        if (!context.mounted) return;
        SnackBarAlerts.showAlertSnackBar("You can't add yourself", context);
        return;
      }

      // If the user is already in the list or a member of the group, we show a warning
      if (users
              .where((user) =>
                  user.username.toLowerCase() == username.toLowerCase())
              .isNotEmpty ||
          members
              .where((user) =>
                  user.username.toLowerCase() == username.toLowerCase())
              .isNotEmpty) {
        if (!context.mounted) return;
        SnackBarAlerts.showAlertSnackBar("User already added", context);
        return;
      }

      // If the text field is valid, we add the user
      User? addedUser = await findUser(textEditingController.text);

      // If the user was not found, we show an error
      if (addedUser == null) {
        if (!context.mounted) return;
        SnackBarAlerts.showErrorSnackBar("User not found", context);
        return;
      }
      // If the user was found, we add it to the list
      setState(() {
        users.add(addedUser);
        textEditingController.clear();
      });
    }

    void onRemoveUser(int id, void Function(void Function()) setState) async {
      // We remove the user from the list
      setState(() {
        users.removeWhere((user) => user.id == id);
      });
    }

    return await showContentDialog<List<User>?>(context,
        barrierDismissible: true,
        blurBackground: false,
        title: "Add a New Member",
        content: StatefulBuilder(builder: (context, setState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // FIELD
          InputField(
              autoFocus: true,
              fieldKey: fieldKey,
              controller: textEditingController,
              validator: (arg) {
                if (arg == null || arg.trim().isEmpty) {
                  return "Empty username";
                }
                return Validators.validateUsername(arg)
                    ? null
                    : "Invalid username";
              },
              labelText: "Member Username",
              hintText: AppLocalizations.of(context).signUpPage_Username_Field,
              suffixIcon:
                  textEditingController.text.isEmpty ? null : Icons.close,
              onSuffixIconPressed: () {
                setState(() {
                  textEditingController.clear();
                });
              },
              onChanged: (arg) {
                setState(() {});
              },
              keyboardType: TextInputType.none),
          const SizedBox(
            height: 24,
          ),
          // USERS
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 100),
            child: SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.start,
                spacing: 12,
                runSpacing: 10,
                children: users
                    .map((user) => Container(
                          height: 35,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(90),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: ProfilePicture(
                                  userId: user.id,
                                  imageUrl: user.pfpURL,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                user.username,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 2),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: GestureDetector(
                                  onTap: () => onRemoveUser(user.id, setState),
                                  child: Icon(
                                    Icons.close,
                                    size: 24,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainer,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          if (users.isNotEmpty)
            const SizedBox(
              height: 24,
            ),
          // ADD
          AppButton(
              size: AppButtonSize.small,
              style: AppButtonStyle.filled,
              intent: AppButtonIntent.primary,
              fontSize: 20,
              onPressed: () async {
                if (!isLoading) {
                  await onConfirm(textEditingController.text, setState);
                  isLoading = false;
                }
              },
              child:
                  Text(textEditingController.text.isEmpty ? "Confirm" : "Add"))
        ],
      );
    }));
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
                      Form(
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
                                  keyboardType: TextInputType.none,
                                );
                              },
                              separatorBuilder: (context, index) {
                                return const SizedBox(
                                  height: 24,
                                );
                              },
                              itemCount: fields.length)),
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

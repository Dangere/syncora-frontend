// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/utils/validators.dart';
import 'package:syncora_frontend/features/authentication/models/google_register_user_info.dart';

class AuthPopups {
  static Future<GoogleRegisterUserInfo?> displayRegisterInfoGetter(
      BuildContext context, WidgetRef ref) async {
    final _contentKey = GlobalKey<AuthDialogAlertContentState>();

    bool isFinished = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.person),

          // actionsOverflowAlignment: OverflowBarAlignment.center,
          title: Text(
            "User Info",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          content: AuthDialogAlertContent(key: _contentKey),

          actions: [
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () {
                  if (!_contentKey.currentState!.validateForm()) return;
                  isFinished = true;
                  Navigator.of(context).pop();
                },
                child: const Text("Finish")),
          ],
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.all(15),
        );
      },
    );

    if (isFinished) {
      Logger().w("Finished registering");
      GoogleRegisterUserInfo userInfo = _contentKey.currentState!.userInfo;
      return userInfo;
    } else {
      return null;
    }
  }
}

class AuthDialogAlertContent extends StatefulWidget {
  const AuthDialogAlertContent({Key? key}) : super(key: key);

  @override
  State<AuthDialogAlertContent> createState() => AuthDialogAlertContentState();
}

class AuthDialogAlertContentState extends State<AuthDialogAlertContent> {
  final _formKey = GlobalKey<FormState>();

  bool showPassword = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    super.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  bool validateForm() => _formKey.currentState!.validate();

  GoogleRegisterUserInfo get userInfo {
    return GoogleRegisterUserInfo(
        username: usernameController.text.trim(),
        password: passwordController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: IntrinsicHeight(
          child: Column(children: [
            // Username field
            TextFormField(
              decoration: const InputDecoration(labelText: 'Username'),
              keyboardType: TextInputType.emailAddress,
              controller: usernameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Username cannot be empty';
                }

                if (Validators.validateUsername(value.trim()) == false) {
                  return 'Invalid username';
                }
                return null;
              },
            ),
            // Passwords field
            StatefulBuilder(builder: (context, setState) {
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'Password'),
                          obscureText: !showPassword,
                          controller: passwordController,
                          keyboardType: TextInputType.visiblePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password cannot be empty';
                            }

                            if (Validators.validatePassword(value.trim()) ==
                                false) {
                              return 'Password must be between 6 and 16 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: IconButton(
                            alignment: Alignment.center,
                            onPressed: () {
                              setState(() {
                                showPassword = !showPassword;
                              });
                            },
                            icon: Icon(!showPassword
                                ? Icons.remove_red_eye_outlined
                                : Icons.remove_red_eye)),
                      )
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Confirm Password'),
                          obscureText: !showPassword,
                          controller: confirmPasswordController,
                          keyboardType: TextInputType.visiblePassword,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password cannot be empty';
                            }

                            if (value.trim() !=
                                passwordController.text.trim()) {
                              return "Password does not match";
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: IconButton(
                            alignment: Alignment.center,
                            onPressed: () {
                              setState(() {
                                showPassword = !showPassword;
                              });
                            },
                            icon: Icon(!showPassword
                                ? Icons.remove_red_eye_outlined
                                : Icons.remove_red_eye)),
                      )
                    ],
                  ),
                ],
              );
            }),
          ]),
        ));
  }
}

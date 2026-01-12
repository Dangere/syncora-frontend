import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations_ar.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations_en.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/core/utils/validators.dart';
import 'package:syncora_frontend/features/authentication/view/popups/auth_popups.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool showPassword = false;

  @override
  void dispose() {
    super.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider);

    SnackBarAlerts.registerErrorListener(ref, context);

    void signUp() {
      if (!_formKey.currentState!.validate() || user.isLoading) return;
      ref.read(authNotifierProvider.notifier).registerWithEmailAndPassword(
          emailController.text.trim(),
          usernameController.text.trim(),
          passwordController.text.trim());
    }

    void googleSignUp() {
      ref.read(authNotifierProvider.notifier).registerUsingGoogle(
            (p0) => AuthPopups.displayRegisterInfoGetter(context, ref),
          );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(),
      body: OverlayLoader(
        isLoading: user.isLoading,
        overlay: const CircularProgressIndicator(),
        body: SingleChildScrollView(
          child: Padding(
            padding: AppSpacing.paddingHorizontalLg +
                AppSpacing.paddingVerticalXl +
                const EdgeInsets.only(top: 50),
            child: Column(
              children: [
                // TITLE
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context).signUpPage_Title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 38),
                Form(
                    key: _formKey,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // FIRST NAME
                              Expanded(
                                child: InputField(
                                  keyboardType: TextInputType.name,
                                  hintText: AppLocalizations.of(context)
                                      .signUpPage_Name_Field,
                                  labelText: AppLocalizations.of(context)
                                      .signUpPage_FirstName,
                                  controller: firstNameController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'First name cannot be empty';
                                    }

                                    if (Validators.validateUsername(
                                            value.trim()) ==
                                        false) {
                                      return 'Invalid first name';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              AppSpacing.horizontalSpaceMd,

                              // LAST NAME
                              Expanded(
                                child: InputField(
                                  keyboardType: TextInputType.name,
                                  hintText: AppLocalizations.of(context)
                                      .signUpPage_Name_Field,
                                  labelText: AppLocalizations.of(context)
                                      .signUpPage_LastName,
                                  controller: lastNameController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Last name cannot be empty';
                                    }

                                    if (Validators.validateUsername(
                                            value.trim()) ==
                                        false) {
                                      return 'Invalid last name';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // USERNAME
                          InputField(
                            suffixIcon: Icons.person_outline_rounded,
                            keyboardType: TextInputType.name,
                            labelText: AppLocalizations.of(context)
                                .signUpPage_Username,
                            hintText: AppLocalizations.of(context)
                                .signUpPage_Username_Field,
                            controller: usernameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Username cannot be empty';
                              }

                              if (Validators.validateUsername(value.trim()) ==
                                  false) {
                                return 'Invalid username';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // EMAIL
                          InputField(
                            suffixIcon: Icons.email_outlined,
                            labelText: AppLocalizations.of(context).email,
                            hintText: AppLocalizations.of(context).email_Field,
                            keyboardType: TextInputType.emailAddress,
                            controller: emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email cannot be empty';
                              }

                              if (Validators.validateEmail(value.trim()) ==
                                  false) {
                                return 'Invalid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          StatefulBuilder(
                            builder: (context, setState) {
                              return Column(
                                children: [
                                  // PASSWORD
                                  InputField(
                                    obscureText: !showPassword,
                                    suffixIcon: showPassword
                                        ? Icons.remove_red_eye_rounded
                                        : Icons.remove_red_eye_outlined,
                                    keyboardType: TextInputType.visiblePassword,
                                    labelText:
                                        AppLocalizations.of(context).password,
                                    hintText: AppLocalizations.of(context)
                                        .password_Field,
                                    controller: passwordController,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password cannot be empty';
                                      }

                                      if (Validators.validatePassword(
                                              value.trim()) ==
                                          false) {
                                        return 'Password must be between 6 and 16 characters';
                                      }
                                      return null;
                                    },
                                    onSuffixIconPressed: () {
                                      setState(() {
                                        showPassword = !showPassword;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  // CONFIRM PASSWORD
                                  InputField(
                                    obscureText: !showPassword,
                                    suffixIcon: showPassword
                                        ? Icons.remove_red_eye_rounded
                                        : Icons.remove_red_eye_outlined,
                                    keyboardType: TextInputType.visiblePassword,
                                    labelText: AppLocalizations.of(context)
                                        .signUpPage_ConfirmPassword,
                                    hintText: AppLocalizations.of(context)
                                        .signUpPage_ConfirmPassword_Field,
                                    controller: confirmPasswordController,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Password cannot be empty';
                                      }

                                      if (value.trim() !=
                                          passwordController.text.trim()) {
                                        return "Password does not match";
                                      }
                                      return null;
                                    },
                                    onSuffixIconPressed: () {
                                      setState(() {
                                        showPassword = !showPassword;
                                      });
                                    },
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 24),
                          // SIGN UP
                          AppButton(
                              variant: AppButtonVariant.primary,
                              onPressed: signUp,
                              child: Text(AppLocalizations.of(context).signUp)),
                          const SizedBox(height: 12),

                          // GOOGLE SIGN UP
                          AppButton(
                              variant: AppButtonVariant.glow,
                              onPressed: googleSignUp,
                              child: Text(AppLocalizations.of(context).signUp))
                        ]))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InputField extends StatelessWidget {
  const InputField({
    super.key,
    required this.controller,
    required this.validator,
    required this.labelText,
    required this.hintText,
    required this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixIconPressed,
  });
  final String labelText;
  final String hintText;
  final bool obscureText;

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final VoidCallback? onSuffixIconPressed;

  final IconData? suffixIcon;

  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Stack(
      // alignment: Alignment.bottomLeft,

      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 5, bottom: 8),
              child: Text(labelText,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 45),
              child: TextFormField(
                keyboardType: keyboardType,
                obscureText: obscureText,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: hintText,
                  suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
                ),
                controller: controller,
                validator: validator,
              ),
            ),
          ],
        ),
        Positioned(
            top: 30,
            right: 0,
            child: GestureDetector(
              onTap: () {
                if (suffixIcon != null && onSuffixIconPressed != null) {
                  onSuffixIconPressed!();
                }
              },
              child: Container(
                // color: Colors.red.withOpacity(0.2),
                child: SizedBox(
                  height: 45,
                  width: 45,
                  child: Center(
                      child: Icon(suffixIcon, color: Colors.transparent)),
                ),
              ),
            )),
      ],
    );
  }
}

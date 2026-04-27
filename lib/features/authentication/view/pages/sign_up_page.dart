import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/input_field.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/core/utils/validators.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/authentication/google_auth_type_enum.dart';

import '../widgets/google_auth_button_stud.dart';

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
    final user = ref.watch(authProvider);

    SnackBarAlerts.registerNotificationListener(ref, context);

    void signUp() {
      if (!_formKey.currentState!.validate() || user.isLoading) return;
      ref.read(authProvider.notifier).registerWithEmailAndPassword(
          email: emailController.text.trim(),
          username: usernameController.text.trim(),
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          password: passwordController.text.trim());
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(),
      body: OverlayLoader(
        isLoading: user.isLoading,
        body: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: AppSpacing.paddingHorizontalLg +
                    AppSpacing.paddingVerticalXl +
                    const EdgeInsets.only(top: 80),
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
                    const SizedBox(height: 30),
                    Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // FIRST AND LAST NAME
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
                                      return AppLocalizations.of(context)
                                          .validation_Name_Empty;
                                    }

                                    if (Validators.validateName(value.trim()) ==
                                        false) {
                                      return AppLocalizations.of(context)
                                          .validation_Name_Invalid;
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
                                      return AppLocalizations.of(context)
                                          .validation_Name_Empty;
                                    }

                                    if (Validators.validateName(value.trim()) ==
                                        false) {
                                      return AppLocalizations.of(context)
                                          .validation_Name_Invalid;
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
                                return AppLocalizations.of(context)
                                    .validation_Username_Empty;
                              }

                              if (Validators.validateUsername(value.trim()) ==
                                  false) {
                                return AppLocalizations.of(context)
                                    .validation_Username_Invalid;
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
                                return AppLocalizations.of(context)
                                    .validation_Email_Empty;
                              }

                              if (Validators.validateEmail(value.trim()) ==
                                  false) {
                                return AppLocalizations.of(context)
                                    .validation_Email_Invalid;
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
                                        return AppLocalizations.of(context)
                                            .validation_Password_Empty;
                                      }

                                      if (Validators.validatePassword(
                                              value.trim()) ==
                                          false) {
                                        return AppLocalizations.of(context)
                                            .validation_Password_Invalid;
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
                                        return AppLocalizations.of(context)
                                            .validation_Password_Empty;
                                      }

                                      if (Validators.validatePassword(
                                              value.trim()) ==
                                          false) {
                                        return AppLocalizations.of(context)
                                            .validation_Password_Invalid;
                                      }

                                      if (value.trim() !=
                                          passwordController.text.trim()) {
                                        return AppLocalizations.of(context)
                                            .validation_Password_Not_Matching;
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // SIGN UP
                    AppButton(
                        size: AppButtonSize.large,
                        style: AppButtonStyle.filled,
                        intent: AppButtonIntent.primary,
                        onPressed: signUp,
                        child: Text(AppLocalizations.of(context).signUp)),
                    const SizedBox(height: 24),

                    // GOOGLE SIGN UP
                    const GoogleAuthButton(
                      type: GoogleAuthType.signUp,
                    ),
                    const Spacer(),

                    // FOOTER
                    TextButton(
                      onPressed: () {
                        context.replaceNamed('sign-in');
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline),
                              "${AppLocalizations.of(context).onboardingPage_AlreadyHaveAccount} "),
                          Text(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                              AppLocalizations.of(context).signIn)
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

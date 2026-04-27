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

import 'package:syncora_frontend/features/authentication/view/widgets/google_auth_button_stud.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool showPassword = false;

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    SnackBarAlerts.registerNotificationListener(ref, context);

    void signIn() {
      // Check if form is valid before attempting to login
      if (!_formKey.currentState!.validate() || user.isLoading) return;
      ref.read(authProvider.notifier).loginWithEmailAndPassword(
          email: emailController.text.trim(),
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
                          AppLocalizations.of(context).signInPage_Title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 87),

                    Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // EMAIL
                          InputField(
                            // suffixIcon: Icons.email_outlined,
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
                          const SizedBox(height: 28),

                          StatefulBuilder(
                            builder: (context, setState) {
                              return InputField(
                                obscureText: !showPassword,
                                suffixIcon: showPassword
                                    ? Icons.remove_red_eye_rounded
                                    : Icons.remove_red_eye_outlined,
                                keyboardType: TextInputType.visiblePassword,
                                labelText:
                                    AppLocalizations.of(context).password,
                                hintText:
                                    AppLocalizations.of(context).password_Field,
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
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // const SizedBox(height: 12),

                    // FORGOT PASSWORD
                    Row(
                      children: [
                        TextButton(
                            onPressed: () =>
                                context.pushNamed('reset-password'),
                            child: Text(
                              AppLocalizations.of(context)
                                  .signInPage_ForgotPassword,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                    decoration: TextDecoration.underline,
                                  ),
                            )),
                      ],
                    ),

                    const SizedBox(height: 70),

                    // SIGN IN
                    AppButton(
                        size: AppButtonSize.large,
                        style: AppButtonStyle.filled,
                        intent: AppButtonIntent.primary,
                        onPressed: signIn,
                        child: Text(AppLocalizations.of(context).signIn)),
                    const SizedBox(height: 24),

                    // GOOGLE SIGN IN
                    const GoogleAuthButton(
                      type: GoogleAuthType.signIn,
                    ),
                    const SizedBox(height: 25),
                    const Spacer(),

                    // FOOTER
                    TextButton(
                      onPressed: () {
                        context.replaceNamed('sign-up');
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
                              "${AppLocalizations.of(context).signInPage_NotAUser} "),
                          Text(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                              AppLocalizations.of(context).signUp)
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/input_field.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/core/utils/validators.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';

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
  void initState() {
    super.initState();
    ref.read(loggerProvider).d('Sign up page initialized');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider);

    SnackBarAlerts.registerErrorListener(ref, context);

    void signIn() {
      // Check if form is valid before attempting to login
      if (!_formKey.currentState!.validate() || user.isLoading) return;
      ref.read(authNotifierProvider.notifier).loginWithEmailAndPassword(
          emailController.text.trim(), passwordController.text.trim());
    }

    void googleSignIn() {
      ref.read(authNotifierProvider.notifier).loginUsingGoogle();
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
                        variant: AppButtonVariant.primary,
                        onPressed: signIn,
                        child: Text(AppLocalizations.of(context).signIn)),
                    const SizedBox(height: 12),

                    // GOOGLE SIGN IN
                    AppButton(
                        variant: AppButtonVariant.glow,
                        onPressed: googleSignIn,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              "assets/logos/google-icon.svg",
                              semanticsLabel: 'Google Logo',
                              height: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                                AppLocalizations.of(context)
                                    .signInPage_GoogleSignIn,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant)),
                          ],
                        )),
                    const SizedBox(height: 25),
                    const Spacer(),

                    // FOOTER
                    TextButton(
                      onPressed: () {
                        context.replace('/sign-up');
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

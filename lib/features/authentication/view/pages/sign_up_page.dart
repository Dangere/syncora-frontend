import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/input_field.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Spacer(),

                    // SIGN UP
                    AppButton(
                        size: AppButtonSize.large,
                        style: AppButtonStyle.filled,
                        intent: AppButtonIntent.primary,
                        onPressed: signUp,
                        child: Text(AppLocalizations.of(context).signUp)),
                    const SizedBox(height: 24),

                    // GOOGLE SIGN UP
                    AppButton(
                        size: AppButtonSize.large,
                        style: AppButtonStyle.glow,
                        onPressed: googleSignUp,
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
                                    .signUpPage_GoogleSignUp,
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
                    const SizedBox(height: 15),

                    // FOOTER
                    TextButton(
                      onPressed: () {
                        context.replace('/sign-in');
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

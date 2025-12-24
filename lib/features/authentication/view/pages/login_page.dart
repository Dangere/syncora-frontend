import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/core/utils/alert_dialogs.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/core/utils/validators.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
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
    ref.read(loggerProvider).d('Login page initialized');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider);

    SnackBarAlerts.registerErrorListener(ref, context);

    void login() {
      // Check if form is valid before attempting to login
      if (!_formKey.currentState!.validate() || user.isLoading) return;
      ref.read(authNotifierProvider.notifier).loginWithEmailAndPassword(
          emailController.text.trim(), passwordController.text.trim());
    }

    void googleLogin() {
      ref.read(authNotifierProvider.notifier).loginUsingGoogle();
    }

    void guestLogin() {
      if (user.isLoading) return;

      AlertDialogs.showTextFieldDialog(context,
          barrierDismissible: true,
          blurBackground: true,
          message: AppLocalizations.of(context).loginPage_guestPopTitle,
          onContinue: (p0) =>
              {ref.read(authNotifierProvider.notifier).loginAsGuest(p0)},
          validation: (p0) {
            if (p0.isEmpty) {
              return AppLocalizations.of(context).loginPage_guestPopError_empty;
            }
            if (!Validators.validateUsername(p0)) {
              return AppLocalizations.of(context)
                  .loginPage_guestPopError_invalid;
            }
            return null;
          });
    }

    // return Placeholder();

    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(AppLocalizations.of(context).loginPageTitle)),
      ),
      body: OverlayLoader(
        isLoading: user.isLoading,
        overlay: const CircularProgressIndicator(),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Title
            Text("Syncora",
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge!
                    .copyWith(fontSize: 60)
                    .copyWith(color: Theme.of(context).colorScheme.primary)
                    .copyWith(fontWeight: FontWeight.bold)),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.1,
            ),
            // Forms and login buttons
            Column(
              children: [
                Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Email'),
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
                          // Password field
                          StatefulBuilder(builder: (context, setState) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: 'Password'),
                                    obscureText: !showPassword,
                                    controller: passwordController,
                                    keyboardType: TextInputType.visiblePassword,
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
                            );
                          }),
                          AppSpacing.verticalSpaceSm,
                          TextButton(
                              style: ButtonStyle(
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(0.0),
                                    ),
                                  ),
                                  padding: MaterialStateProperty.all(
                                      const EdgeInsets.all(0))),
                              onPressed: () {
                                context.pushNamed('reset-password');
                              },
                              child: Text("Forgot Password?")),

                          // SizedBox(height: 100),
                          // Register button
                        ]),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        onPressed: login,
                        child: Text(AppLocalizations.of(context).loginButton)),
                    ElevatedButton(
                        onPressed: guestLogin,
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                                Colors.grey.shade200)),
                        child: Text(
                            AppLocalizations.of(context).guestLoginButton,
                            style: const TextStyle(color: Colors.black))),
                  ],
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: ElevatedButton(
                    onPressed: googleLogin,
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.grey.shade200),
                        padding: MaterialStateProperty.all(
                            const EdgeInsets.all(10))),
                    child: Container(
                      // color: Colors.amber,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SizedBox(
                            height: 25,
                            width: 25,
                            child: SvgPicture.asset(
                                "assets/logos/google-icon.svg",
                                semanticsLabel: 'Google Logo'),
                          ),
                          SizedBox(width: 9),
                          const Text("Sign in with Google",
                              style: TextStyle(color: Colors.black)),
                        ],
                      ),
                    )),
              ),
            ),
            // Footer
            Column(
              children: [
                TextButton(
                    onPressed: () {
                      // TODO: Put register screen nav here
                      context.replace('/register');
                    },
                    child: SizedBox(
                      width: 200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                              style: Theme.of(context).textTheme.bodyMedium,
                              "Not a user? "),
                          Text(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                              "Register"),
                        ],
                      ),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

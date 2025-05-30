import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    void guestLogin() {
      if (user.isLoading) return;

      AlertDialogs.showTextFieldDialog(context,
          barrierDismissible: true,
          blurBackground: true,
          message: "Guest Username",
          onContinue: (p0) =>
              {ref.read(authNotifierProvider.notifier).loginAsGuest(p0)},
          validation: (p0) {
            if (p0.isEmpty) {
              return "guest username cannot be empty";
            }
            if (!Validators.validateUsername(p0)) {
              return "invalid username format";
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
        body: Form(
          key: _formKey,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("Syncora",
                    style: Theme.of(context).textTheme.headlineLarge),

                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: SizedBox(
                    height: 300,
                    child: Column(
                      children: [
                        // Email field

                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Email'),
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
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'Password'),
                          obscureText: false,
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
                        AppSpacing.horizontalSpaceLg,
                        ElevatedButton(
                            onPressed: login,
                            child:
                                Text(AppLocalizations.of(context).loginButton)),
                        AppSpacing.horizontalSpaceLg,
                      ],
                    ),
                  ),
                ),
                // SizedBox(height: 100),

                ElevatedButton(
                    onPressed: guestLogin,
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.grey.shade200)),
                    child: Text(AppLocalizations.of(context).guestLoginButton,
                        style: const TextStyle(color: Colors.black))),
              ]),
        ),
      ),
    );
  }
}

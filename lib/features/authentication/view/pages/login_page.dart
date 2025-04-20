import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
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
    final authNotifier = ref.read(authProvider.notifier);
    final user = ref.watch(authProvider);

    // Show error snackbar when error is not null in the auth state
    ref.listen(authProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ref.read(loggerProvider).d('Showing snackbar');
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error.toString()),
        ));
      }
    });

    void login() {
      // Check if form is valid before attempting to login
      // if (!_formKey.currentState!.validate() || user.isLoading) return;
      authNotifier.loginWithEmailAndPassword(
          emailController.text.trim(), passwordController.text.trim());
    }

    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(AppLocalizations.of(context).loginPageTitle)),
      ),
      body: Form(
        key: _formKey,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(AppLocalizations.of(context).loginPageTitle),
          // Email field
          TextFormField(
            keyboardType: TextInputType.emailAddress,
            controller: emailController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email cannot be empty';
              }

              if (Validators.validateEmail(value.trim()) == false) {
                return 'Invalid email';
              }
              return null;
            },
          ),
          // Password field
          TextFormField(
            obscureText: false,
            controller: passwordController,
            keyboardType: TextInputType.visiblePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password cannot be empty';
              }

              if (Validators.validatePassword(value.trim()) == false) {
                return 'Password must be between 6 and 16 characters';
              }
              return null;
            },
          ),
          ElevatedButton(
              onPressed: login,
              child: user.isLoading
                  ? const CircularProgressIndicator()
                  : Text(AppLocalizations.of(context).loginButton))
        ]),
      ),
    );
  }
}

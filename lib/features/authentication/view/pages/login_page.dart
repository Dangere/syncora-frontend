import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authViewModel = ref.read(authProvider.notifier);
    AuthState state = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
        ));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).loginPageTitle),
        leading: state.isLoading ? const CircularProgressIndicator() : null,
      ),
      body: Column(children: [
        ElevatedButton(
            onPressed: () {
              authViewModel.loginWithEmailAndPassword(
                  "user@gmail.com", "NOTCRddEATED");
            },
            child: const Text('Login Now')),
        ElevatedButton(
            onPressed: () {
              authViewModel.registerWithEmailAndPassword(
                  "usdsder@gmail.com", "NOTCREATED", "NOTCREATED");
            },
            child: const Text('Register Now'))
      ]),
    );
  }
}

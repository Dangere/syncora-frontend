import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authViewModel = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).loginPageTitle),
      ),
      body: Column(children: [
        ElevatedButton(
            onPressed: () {
              authViewModel.loginWithEmailAndPassword(
                  "user@gmail.com", "NOTCREATED");
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

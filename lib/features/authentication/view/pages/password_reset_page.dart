import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/core/utils/validators.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';

class PasswordResetPage extends ConsumerStatefulWidget {
  const PasswordResetPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PasswordResetPageState();
}

class _PasswordResetPageState extends ConsumerState<PasswordResetPage> {
  final TextEditingController emailController = TextEditingController();
  final _emailFieldKey = GlobalKey<FormFieldState>();
  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
  }

  // TODO: this could be refactored to use a provider instead of manually managing the state (careful of ephemeral state)
  void resetPassword() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });
    Result result = await ref
        .read(authNotifierProvider.notifier)
        .requestPasswordReset(emailController.text.trim());

    if (result.isSuccess) {
      SnackBarAlerts.showSuccessSnackBar("Password reset email sent", context);
    }

    if (!mounted) return;
    setState(() {
      emailController.clear();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    SnackBarAlerts.registerErrorListener(ref, context);

    return Scaffold(
        appBar: AppBar(
          shape: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.inversePrimary,
              width: 3,
            ),
          ),
          title: const Text("Password Reset"),
        ),
        body: OverlayLoader(
          isLoading: isLoading,
          overlay: const CircularProgressIndicator(),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: 50,
              ),
              Text("Syncora",
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge!
                      .copyWith(fontSize: 60)
                      .copyWith(color: Theme.of(context).colorScheme.primary)
                      .copyWith(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 100,
              ),
              Container(
                child: Column(
                  children: [
                    Text(
                      "Please enter your email to reset your password",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50.0, vertical: 20),
                      child: Container(
                        // padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextFormField(
                          key: _emailFieldKey,
                          controller: emailController,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          // controller: emailController,
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
                      ),
                    ),
                    AppSpacing.verticalSpaceLg,
                    ElevatedButton(
                        onPressed: () {
                          if (_emailFieldKey.currentState!.validate()) {
                            resetPassword();
                          }
                        },
                        child: Text("Reset Password")),
                    AppSpacing.verticalSpaceMd,
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Back to Login")),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

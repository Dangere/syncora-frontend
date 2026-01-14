import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/input_field.dart';
import 'package:syncora_frontend/common/widgets/overlay_loader.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
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
    if (isLoading || ref.read(resetPasswordTimerNotifierProvider) != null) {
      return;
    }
    setState(() {
      isLoading = true;
      ref.read(resetPasswordTimerNotifierProvider.notifier).startTimer(30);
    });
    Result result = await ref
        .read(authNotifierProvider.notifier)
        .requestPasswordReset(emailController.text.trim());

    if (result.isSuccess) {
      SnackBarAlerts.showSuccessSnackBar("Password reset email sent", context);
    }

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  String formatTwoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    SnackBarAlerts.registerErrorListener(ref, context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(),
      body: OverlayLoader(
        isLoading: isLoading,
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
                          AppLocalizations.of(context).passwordRestPage_Title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 96),
                    // DESCRIPTION
                    Text(
                      AppLocalizations.of(context).passwordRestPage_Description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 40),
                    // EMAIL FIELD
                    InputField(
                      suffixIcon: Icons.email_outlined,
                      fieldKey: _emailFieldKey,
                      labelText: AppLocalizations.of(context).email,
                      hintText: AppLocalizations.of(context).email_Field,
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

                    const SizedBox(height: 6),

                    Consumer(
                      builder: (context, ref, child) {
                        int? resendTimer =
                            ref.watch(resetPasswordTimerNotifierProvider);

                        return Column(
                          children: [
                            // RESEND EMAIL TIMER
                            if (resendTimer != null)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${AppLocalizations.of(context).passwordRestPage_ResendEmail} ",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant),
                                  ),
                                  Text("00:${formatTwoDigits(resendTimer)}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outlineVariant)),
                                ],
                              ),
                            const SizedBox(height: 74),

                            // RESET PASSWORD
                            AppButton(
                                disabled: resendTimer != null || isLoading,
                                variant: AppButtonVariant.primary,
                                onPressed: () {
                                  if (_emailFieldKey.currentState!.validate()) {
                                    resetPassword();
                                  }
                                },
                                child:
                                    Text(AppLocalizations.of(context).confirm)),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    const Spacer(),
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

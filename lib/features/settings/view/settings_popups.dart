import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/dialogs.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';

class SettingsPopups {
  static void passwordResetPopup(BuildContext context) {
    Dialogs.showContentDialog(context,
        barrierDismissible: true,
        blurBackground: false,
        title: "Password Reset Link",
        content: const PasswordResetPopup());
  }
}

class PasswordResetPopup extends ConsumerStatefulWidget {
  const PasswordResetPopup({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PasswordResetPopupState();
}

class _PasswordResetPopupState extends ConsumerState<PasswordResetPopup> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sendEmail();
    });

    super.initState();
  }

  String formatTwoDigits(int n) => n.toString().padLeft(2, '0');

  void sendEmail() async {
    if (ref.read(resetPasswordTimerProvider) != null) {
      return;
    }

    ref.read(resetPasswordTimerProvider.notifier).startTimer(30);

    if (!ref.read(isAuthenticatedProvider)) {
      return;
    }
    String email = ref.read(authProvider).value?.user?.email ?? "";

    Result result =
        await ref.read(authProvider.notifier).requestPasswordReset(email);

    if (result.isSuccess && mounted) {
      SnackBarAlerts.showSuccessSnackBar("Password reset email sent", context);
    }
  }

  @override
  Widget build(BuildContext context) {
    int? resendTimer = ref.watch(resetPasswordTimerProvider);
    ref.read(loggerProvider).d("Building password pop up");

    return Column(
      children: [
        const SizedBox(
          height: 12,
        ),
        Text("A link has been sent to your email to change your password",
            textAlign: TextAlign.center,
            style:
                Theme.of(context).textTheme.titleSmall!.copyWith(fontSize: 18)),
        const SizedBox(
          height: 27,
        ),
        Text(
          "Didn’t receive a link?",
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.outline),
        ),
        const SizedBox(
          height: 2,
        ),
        SizedBox(
          height: 20,
          child: resendTimer == null
              ? Center(
                  child: GestureDetector(
                    onTap: sendEmail,
                    child: Text(
                      "Resend Email",
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      child: Text(
                        "${AppLocalizations.of(context).passwordRestPage_ResendEmail} ",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color:
                                Theme.of(context).colorScheme.outlineVariant),
                      ),
                    ),
                    Text("00:${formatTwoDigits(resendTimer)}",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color:
                                Theme.of(context).colorScheme.outlineVariant)),
                  ],
                ),
        ),
        const SizedBox(
          height: 12,
        ),
      ],
    );
  }
}

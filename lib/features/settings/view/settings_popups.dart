import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/dialogs.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/users/providers/users_provider.dart';

class SettingsPopups {
  static void passwordResetPopup(BuildContext context) {
    Dialogs.showContentDialog(context,
        barrierDismissible: true,
        blurBackground: false,
        title: AppLocalizations.of(context).settingsPopup_Password_Reset_title,
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

    ref.read(resetPasswordTimerProvider.notifier).startTimer(3);

    if (!ref.read(isAuthenticatedProvider)) {
      return;
    }
    String email = (await ref.read(userProvider.notifier).getMainUser()).email;

    Result result =
        await ref.read(authProvider.notifier).requestPasswordReset(email);

    if (result.isSuccess && mounted) {
      SnackBarAlerts.showSuccessSnackBar(
          AppLocalizations.of(context).settingsPopup_Password_Alert, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    SnackBarAlerts.registerNotificationListener(ref, context);

    int? resendTimer = ref.watch(resetPasswordTimerProvider);
    ref.read(loggerProvider).d("Building password pop up");

    return Column(
      children: [
        const SizedBox(
          height: 12,
        ),
        Text(AppLocalizations.of(context).settingsPopup_Password_Reset,
            textAlign: TextAlign.center,
            style:
                Theme.of(context).textTheme.titleSmall!.copyWith(fontSize: 18)),
        const SizedBox(
          height: 27,
        ),
        Text(
          AppLocalizations.of(context).settingsPopup_Password_NotSent,
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
                      AppLocalizations.of(context)
                          .settingsPopup_Password_Resend,
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

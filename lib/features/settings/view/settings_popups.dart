import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/common/widgets/input_field.dart';
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
        content: EmailSentPopup(
          bodyText: AppLocalizations.of(context).settingsPopup_Password_Reset,
          sendEmail: (ref) async {
            String email =
                (await ref.read(userProvider.notifier).getMainUser()).email;

            Result result = await ref
                .read(authProvider.notifier)
                .requestPasswordReset(email);
            return result.isSuccess;
          },
        ));
  }

  static void accountVerifyPopup(BuildContext context) {
    Dialogs.showContentDialog(context,
        barrierDismissible: true,
        blurBackground: false,
        title: AppLocalizations.of(context).verification,
        content: EmailSentPopup(
          bodyText: AppLocalizations.of(context).alert_verification,
          sendEmail: (ref) async {
            return await ref
                .read(authProvider.notifier)
                .sendVerificationEmail();
          },
        ));
  }

  static Future<String?> reportABugPopup(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    final fieldKey = GlobalKey<FormFieldState>();

    void onConfirm() {
      if (fieldKey.currentState!.validate()) {
        Navigator.of(context).pop(controller.text.trim());
      }
    }

    return await Dialogs.showContentDialog(context,
        barrierDismissible: true,
        blurBackground: false,
        title: AppLocalizations.of(context).settingsPage_ReportBug,
        content: Column(children: [
          InputField(
              fieldKey: fieldKey,
              multiline: true,
              controller: controller,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)
                      .validation_GroupDescription_Empty;
                }
                return null;
              },
              labelText: AppLocalizations.of(context).description,
              hintText: AppLocalizations.of(context).description,
              keyboardType: TextInputType.multiline),

          AppSpacing.verticalSpaceLg,

          // CONFIRM BUTTON
          AppButton(
              breadcrumbLabel: () => "Dialog confirm",
              size: AppButtonSize.small,
              style: AppButtonStyle.filled,
              intent: AppButtonIntent.primary,
              fontSize: 20,
              onPressed: onConfirm,
              child: Text(AppLocalizations.of(context).confirm)),
        ]));
  }
}

class EmailSentPopup extends ConsumerStatefulWidget {
  const EmailSentPopup(
      {super.key, required this.sendEmail, required this.bodyText});

  final Future<bool> Function(WidgetRef ref) sendEmail;
  final String bodyText;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _EmailSentPopupState();
}

class _EmailSentPopupState extends ConsumerState<EmailSentPopup> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sendEmail();
    });

    super.initState();
  }

  String formatTwoDigits(int n) => n.toString().padLeft(2, '0');

  void sendEmail() async {
    if (ref.read(timerProvider) != null) {
      return;
    }

    ref.read(timerProvider.notifier).startTimer(60);

    if (!ref.read(isAuthenticatedProvider)) {
      return;
    }

    bool didSend = await widget.sendEmail(ref);

    if (didSend && mounted) {
      SnackBarAlerts.showSuccessSnackBar(
          AppLocalizations.of(context).settingsPopup_Email_Alert, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    int? resendTimer = ref.watch(timerProvider);

    return Column(
      children: [
        const SizedBox(
          height: 12,
        ),
        Text(widget.bodyText,
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

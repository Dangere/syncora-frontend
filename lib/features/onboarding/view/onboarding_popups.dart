import 'package:flutter/material.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/dialogs.dart'
    show Dialogs, DialogFieldData;
import 'package:syncora_frontend/core/utils/validators.dart';

class OnboardingPopups {
  static Future<String?> guestPopup(BuildContext context) async {
    List<String> data = await Dialogs.showTextFieldDialog(
      context,
      fields: [
        DialogFieldData(
            label: AppLocalizations.of(context).signUpPage_Username,
            validation: (p0) {
              if (p0 == null || p0.isEmpty) {
                return AppLocalizations.of(context)
                    .loginPage_guestPopError_empty;
              }
              if (!Validators.validateUsername(p0)) {
                return AppLocalizations.of(context).validation_Username_Invalid;
              }
              return null;
            })
      ],
      barrierDismissible: true,
      blurBackground: true,
      title: AppLocalizations.of(context).loginPage_guestPopTitle,
      confirmText: AppLocalizations.of(context).confirm,
    );

    if (data.isNotEmpty) return data[0];

    return null;
  }
}

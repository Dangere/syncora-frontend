import 'package:flutter/material.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/dialogs.dart';
import 'package:transparent_image/transparent_image.dart';

class DashboardPopups {
  static Future<void> webAlert(BuildContext context) {
    return Dialogs.showContentDialog(context,
        barrierDismissible: true,
        blurBackground: false,
        title: "${AppLocalizations.of(context).warning}!",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 300,
              child: SingleChildScrollView(
                  child: Column(
                // mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context).dashboard_alert_web),
                  AppSpacing.verticalSpaceMd,
                  Text(AppLocalizations.of(context).dashboard_alert_web_part2),
                  AppSpacing.verticalSpaceMd,
                  FadeInImage(
                    height: 200,
                    placeholder: MemoryImage(kTransparentImage),
                    image: const AssetImage("assets/images/apk_release_qr.png"),
                  ),
                  // const Divider(),
                  AppSpacing.verticalSpaceMd,

                  Text(AppLocalizations.of(context).dashboard_alert_bugReport),
                  AppSpacing.verticalSpaceMd,
                ],
              )),
            ),
            AppSpacing.verticalSpaceMd,
            AppButton(
              size: AppButtonSize.mini,
              style: AppButtonStyle.filled,
              intent: AppButtonIntent.primary,
              fontSize: 18,
              fontWeight: FontWeight.normal,
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context).confirm),
            )
          ],
        ));
  }
}

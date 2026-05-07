import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/dialogs.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardPopups {
  static Future<void> webAlert(BuildContext context) {
    if (!kIsWeb) throw Exception("Tried to show web alert on non-web platform");

    bool isLoadingPage = false;

    Future<void> openDownloadUrl() async {
      isLoadingPage = true;
      final Uri _url = Uri.parse(Constants.APK_DOWNLOAD_URL);
      if (!await launchUrl(_url)) {
        isLoadingPage = false;

        throw Exception('Could not launch $_url');
      }
      isLoadingPage = false;
    }

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
              child: Text(AppLocalizations.of(context).okay),
            ),
            AppSpacing.verticalSpaceMd,
            AppButton(
              size: AppButtonSize.mini,
              style: AppButtonStyle.filled,
              intent: AppButtonIntent.secondary,
              fontSize: 18,
              fontWeight: FontWeight.normal,
              onPressed: () {
                if (!isLoadingPage) openDownloadUrl();
              },
              child: Text(AppLocalizations.of(context).settingsPage_WebAlert),
            ),
          ],
        ));
  }
}

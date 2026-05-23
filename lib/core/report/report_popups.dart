import 'package:flutter/widgets.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/utils/dialogs.dart';

class ReportPopups {
  static Future<void> reportBeenSent(BuildContext context) async {
    await Dialogs.showContentDialog(
      context,
      barrierDismissible: true,
      blurBackground: false,
      title: "",
      content: SizedBox(
        height: 100,
        child: Column(
          children: [
            Text(AppLocalizations.of(context).error_report_popup_sent),
            AppSpacing.verticalSpaceLg,
          ],
        ),
      ),
    );
  }
}

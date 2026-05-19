import 'package:flutter/material.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/core/error_management/app_error.dart';
import 'package:syncora_frontend/core/error_management/app_error_code.dart';
import 'package:syncora_frontend/core/error_management/error_state.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/localization/localize_app_errors.dart';
import 'package:syncora_frontend/core/utils/dialogs.dart';
import 'package:syncora_frontend/core/utils/result.dart';

class ErrorPopups {
  static Future<bool> fetalErrorPopup(
      BuildContext context, ErrorState errorState,
      {required Future<AppErrorCode?> Function(ErrorState errorState)
          onManualSend}) async {
    void onErrorClick(ErrorState error) {
      _displayErrorLog(context, error.error.logMessage);
    }

    // bool canSendDetailsToDev =
    //     errorState is ErrorReport && errorState.reportId != null;
    bool isLoading = false;

    AppErrorCode? errorCodeForSendingDetails;

    bool? didSendError = await Dialogs.showContentDialog<bool?>(
      context,
      barrierDismissible: false,
      blurBackground: true,
      title: "Fetal Error",
      content: StatefulBuilder(builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).error_fetal_popup,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            AppSpacing.verticalSpaceMd,
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(17),
              ),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: GestureDetector(
                    onTap: () => onErrorClick(errorState),
                    child: SizedBox(
                      height: 80,
                      width: double.infinity,
                      child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.surfaceContainer,
                            border: Border.all(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                  child: Text(
                                errorState.error.stackTrace.toString(),
                                overflow: TextOverflow.fade,
                                maxLines: 4,
                                softWrap: true,
                              )),
                              const Center(child: Icon(Icons.expand)),
                            ],
                          )),
                    ),
                  )),
            ),
            AppSpacing.verticalSpaceMd,
            AppButton(
              breadcrumbLabel: () => "Manually send details",
              size: AppButtonSize.mini,
              style: AppButtonStyle.filled,
              intent: AppButtonIntent.secondary,
              fontSize: 18,
              disabled: isLoading,
              fontWeight: FontWeight.normal,
              onPressed: () async {
                if (isLoading) return;
                setState(() {
                  isLoading = true;
                  errorCodeForSendingDetails = null;
                });
                AppErrorCode? error = await onManualSend(errorState);
                setState(() {
                  isLoading = false;
                  errorCodeForSendingDetails = error;
                });

                if (error == null && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
              child: Text(
                  AppLocalizations.of(context).error_fetal_popup_send_button),
            ),
            if (errorCodeForSendingDetails != null) ...[
              AppSpacing.verticalSpaceMd,
              Text(
                LocalizeAppErrors.localizeErrorCode(
                    errorCodeForSendingDetails!, context),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 16),
              ),
              AppSpacing.verticalSpaceMd,
              Text(
                "${AppLocalizations.of(context).error_report_popup_manually}: ${Constants.CONTACT_EMAIL}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              )
            ],
          ],
        );
      }),
    );
    if (didSendError == null) return false;
    return didSendError;
  }

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

  static Future<void> _displayErrorLog(
      BuildContext context, String message) async {
    await Dialogs.showContentDialog(
      context,
      barrierDismissible: true,
      blurBackground: false,
      title: 'ERROR',
      content: SizedBox(
        height: 300,
        child: SingleChildScrollView(child: Text(message)),
      ),
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/error_management/app_error.dart';
import 'package:syncora_frontend/core/error_management/error_popups.dart';
import 'package:syncora_frontend/core/error_management/error_state.dart';
import 'package:syncora_frontend/core/localization/localize_app_errors.dart';
import 'package:syncora_frontend/core/report/report_provider.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/router.dart';

class AppErrorNotifier extends Notifier<ErrorState?> {
  void setError(AppError error, {bool fetal = false}) async {
    var errorState = fetal ? ErrorFetal(error) : ErrorAvailable(error);

    state = errorState;

    // None fetal errors get reported automatically
    if (!fetal) {
      ref.read(reportProvider.notifier).reportError(error);
    }

    // Fetal error get displayed directly to the user then manually reported
    _displayError();
  }

  // sets to an error that made a report fail
  // If the id is missing it means the report failed to be even created
  void setReportError(int? reportId, AppError error) {
    print("next: asdf");

    state = ErrorReport(error, reportId);
    _displayError();
  }

  void _displayError() async {
    BuildContext? context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    if (state! is ErrorFetal || state! is ErrorReport) {
      // If we get an `ErrorFetal` (usually for outbox complete failure)
      // Or an `ErrorReport` (usually when reporting fails)
      bool didSendError = await ErrorPopups.fetalErrorPopup(
        context,
        state!,
        onManualSend: (ErrorState state) async {
          // If the error is a `ErrorReport`, manually send the report
          // If the report id is null, it means that the report failed to even be created
          // So we manually send it as a fetal error instead
          if (state is ErrorReport && state.reportId != null) {
            Result result = await ref
                .read(reportServiceProvider)
                .manuallySubmitReport(state.reportId!, state.error);
            if (result.isSuccess) return null;
            return result.error!.errorCode;
          } else {
            // If the error is a `ErrorFetal` or was `ErrorReport` but the report id is null, manually send the report
            Result result = await ref
                .read(reportServiceProvider)
                .reportFetalError(state.error);
            if (result.isSuccess) return null;
            return result.error!.errorCode;
          }
        },
      );

      if (didSendError && context.mounted) {
        ErrorPopups.reportBeenSent(context);
      }
    } else {
      String localizedErrorMessage =
          LocalizeAppErrors.localizeErrorCode(state!.error.errorCode, context);
      SnackBarAlerts.showErrorSnackBar(localizedErrorMessage, context);
    }

    ref.read(loggerProvider).e("${state!.error.logMessage}\n");
  }

  @override
  ErrorState? build() {
    return null;
  }
}

final appErrorProvider =
    NotifierProvider<AppErrorNotifier, ErrorState?>(AppErrorNotifier.new);

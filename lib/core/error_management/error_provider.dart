import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/error_management/app_error.dart';
import 'package:syncora_frontend/core/error_management/app_error_code.dart';
import 'package:syncora_frontend/core/error_management/error_state.dart';
import 'package:syncora_frontend/core/report/report_provider.dart';
import 'package:syncora_frontend/core/utils/result.dart';

class ErrorHistoryNotifier extends Notifier<List<ErrorState>> {
  void addError(ErrorState error) {
    state = state..add(error);
  }

  @override
  List<ErrorState> build() {
    return [];
  }
}

final errorHistoryProvider =
    NotifierProvider<ErrorHistoryNotifier, List<ErrorState>>(
        ErrorHistoryNotifier.new);

class AppErrorNotifier extends Notifier<ErrorState?> {
  void setError(AppError error, {bool fetal = false}) async {
    var errorState = fetal ? ErrorFetal(error) : ErrorAvailable(error);

    state = errorState;
    ref.read(errorHistoryProvider.notifier).addError(state!);

    // None fetal errors get reported automatically
    if (!fetal) {
      Result<void> result = await ref.read(reportProvider).reportError(error);
      if (!result.isSuccess && !result.isCancelled) {
        setReportError(null, result.error!);
      }
    }

    // Fetal error get displayed directly to the user then manually reported
  }

  // sets to an error that made a report fail
  // If the id is missing it means the report failed to be even created
  void setReportError(int? reportId, AppError error) {
    state = ErrorReport(error, reportId);
    ref.read(errorHistoryProvider.notifier).addError(state!);
  }

  @override
  ErrorState? build() {
    return null;
  }
}

final appErrorProvider =
    NotifierProvider<AppErrorNotifier, ErrorState?>(AppErrorNotifier.new);

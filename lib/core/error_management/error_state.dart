import 'package:syncora_frontend/core/error_management/app_error.dart';

abstract class ErrorState {
  const ErrorState(this.error);
  final AppError error;
}

// Fetal errors get displayed directly to the user UI showing the stacktrace
class ErrorFetal extends ErrorState {
  ErrorFetal(super.error);
}

// Fetal database error get displayed directly to the user and request app restart
class ErrorDbFetal extends ErrorState {
  ErrorDbFetal(super.error);
}

// Available errors get localized into a more user friendly message
class ErrorAvailable extends ErrorState {
  ErrorAvailable(super.error);
}

// Fetal errors when trying to send the error report, used to manually send it
// If report id isnt included, then the report failed to even be created and we only have the error
class ErrorReport extends ErrorState {
  final int? reportId;
  ErrorReport(super.error, this.reportId);
}

// import 'package:signalr_netcore/errors.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/core/data/enums/app_error_code.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';

// Currently there is no way to know if we should ignore this error and not print it, so far it will always have a value to print
class AppError {
  // This is what gets used to from a localized message to the user
  final AppErrorCode errorCode;

  // This is a raw message for further debugging
  final String rawMessage;

  // This is what gets logged
  final String logMessage;

  final Exception? exception;
  final StackTrace stackTrace;

  AppError(
      {required this.errorCode,
      required this.rawMessage,
      required this.logMessage,
      required this.stackTrace,
      this.exception});

  // Takes exceptions and localizes it to a user friendly message, or when undefined, return a generic error
  factory AppError.fromException(Object e, StackTrace stackTrace) {
    String rawMessage =
        e is DioException ? e.response.toString() : e.toString();
    return AppError(
        errorCode: ErrorMapper.mapError(e),
        rawMessage: rawMessage,
        logMessage: ErrorMapper.parseLogMessage(
            rawMessage, stackTrace, StackTrace.current),
        stackTrace: stackTrace,
        exception: e is Exception ? e : null);
  }

  // Takes an app error code and localizes it to a user friendly message
  factory AppError.fromCode(AppErrorCode code, StackTrace stackTrace) {
    return AppError(
        errorCode: code,
        rawMessage: code.toString(),
        logMessage: ErrorMapper.parseLogMessage(
            code.toString(), stackTrace, StackTrace.current),
        stackTrace: stackTrace,
        exception: null);
  }

//   String localizeError(BuildContext context) =>
//       AppLocalizations.of(context).error(errorCode.toString());

  AsyncValue<T> toAsyncValue<T>() =>
      AsyncValue<T>.error(Exception(errorCode.toString()), stackTrace);
}

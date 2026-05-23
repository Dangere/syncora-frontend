// import 'package:signalr_netcore/errors.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/core/error_management/app_error_code.dart';
import 'package:syncora_frontend/core/error_management/error_mapper.dart';

/// A class to represent an error
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

  /// Creates an [AppError] from exception which gets mapped to an error code for further user localized messages
  factory AppError.fromException(Object e, StackTrace stackTrace) {
    String rawMessage = e.toString();

    if (e is DioException && e.response != null) {
      rawMessage +=
          '\n' + e.response.toString() + '\n' + e.response!.data.toString();
    }
    return AppError(
        errorCode: ErrorMapper.mapError(e),
        rawMessage: rawMessage,
        logMessage: ErrorMapper.parseLogMessage(
            rawMessage, stackTrace, StackTrace.current),
        stackTrace: stackTrace,
        exception: e is Exception ? e : null);
  }

  /// Creates an [AppError] from a code error directly
  factory AppError.fromCode(AppErrorCode code, StackTrace stackTrace) {
    return AppError(
        errorCode: code,
        rawMessage: code.toString(),
        logMessage: ErrorMapper.parseLogMessage(
            code.toString(), stackTrace, StackTrace.current),
        stackTrace: stackTrace,
        exception: null);
  }

  /// Used to transform an [AppError] into an [AsyncValue] Error for Riverpod's notifiers
  AsyncValue<T> toAsyncValue<T>() =>
      AsyncValue<T>.error(Exception(errorCode.toString()), stackTrace);
}

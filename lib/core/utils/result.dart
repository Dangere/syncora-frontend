import 'package:cancellation_token/cancellation_token.dart';
import 'package:flutter/foundation.dart';
import 'package:syncora_frontend/core/data/enums/app_error_code.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';

class Result<T> {
  final T? data;
  final AppError? error;

  Result({this.data, this.error});

  bool get isSuccess => error == null;
  bool get isCancelled => error?.exception is CancelledException;

  static Result<T> success<T>([T? data]) => Result<T>(data: data);

  static Result<T> failureError<T>(Object error, StackTrace stackTrace) =>
      Result<T>(error: AppError.fromException(error, stackTrace));

  static Result<T> failureCode<T>(AppErrorCode code, StackTrace stackTrace) =>
      Result<T>(error: AppError.fromCode(code, stackTrace));

  static Result<T> failureFrom<T>(Result result) =>
      Result<T>(error: result.error);

  static Result<T> canceled<T>(String message, StackTrace stackTrace) =>
      Result<T>(
          error: AppError.fromException(
              CancelledException(cancellationReason: message), stackTrace));

  static Result<void> wrap(VoidCallback callback) {
    try {
      callback();
      return Result.success();
    } catch (e, stackTrace) {
      return Result.failureError(e, stackTrace);
    }
  }

  static Future<Result<T>> wrapAsync<T>(Future<T> Function() callback) async {
    try {
      T result = await callback();
      return Result.success(result);
    } catch (e, stackTrace) {
      return Result.failureError(e, stackTrace);
    }
  }
}

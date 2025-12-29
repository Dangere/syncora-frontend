import 'package:cancellation_token/cancellation_token.dart';
import 'package:flutter/foundation.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';

class Result<T> {
  final T? data;
  final AppError? error;

  Result({this.data, this.error});

  bool get isSuccess => error == null;
  bool get isCancelled => error?.errorObject is CancelledException;

  // Helper methods to make the API cleaner
  static Result<T> success<T>([T? data]) => Result<T>(data: data);

  static Result<T> failure<T>(Object exception, StackTrace stackTrace) =>
      Result<T>(error: ErrorMapper.map(exception, stackTrace));

  static Result<T> canceled<T>(String message) => Result<T>(
      error:
          AppError(message: message, errorObject: const CancelledException()));

  static Result<T> failureMessage<T>(String message) =>
      Result<T>(error: AppError(message: message));

  static Result<void> wrap(VoidCallback callback) {
    try {
      callback();
      return Result.success();
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  static Future<Result<T>> wrapAsync<T>(Future<T> Function() callback) async {
    try {
      T result = await callback();
      return Result.success(result);
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  // TODO: replace all the manual if checks for the isSuccess in other classes with these fluent methods
  Result<T> onSuccess(void Function(T data) callback) {
    if (isSuccess) callback(data as T);

    return this;
  }

  Result<T> onError(void Function(AppError error) callback) {
    if (!isSuccess && !isCancelled) callback(error!);

    return this;
  }

  E? errorObject<E>() => error?.errorObject as E;
}

import 'package:flutter/foundation.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';

class Result<T> {
  final T? data;
  final AppError? error;

  Result({this.data, this.error});

  bool get isSuccess => error == null;

  // Helper methods to make the API cleaner
  static Result<T> success<T>(T data) => Result<T>(data: data);

  static Result<T> failure<T>(AppError error) => Result<T>(error: error);
  static Result<T> failureMessage<T>(String message) =>
      Result<T>(error: AppError(message: message));

  static Result<void> wrap(VoidCallback callback) {
    try {
      callback();
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }
}

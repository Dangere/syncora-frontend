import 'package:dio/dio.dart';
import 'package:signalr_netcore/errors.dart';

class AppError<T extends Exception> {
  final String message;
  final StackTrace? stackTrace;
  final T errorObject;
  AppError({required this.message, T? errorObject, this.stackTrace})
      : errorObject = (errorObject ?? Exception(message) as T);

  bool is401UnAuthorizedError() {
    if (errorObject is DioException) {
      if ((errorObject as DioException).response!.statusCode == 401) {
        return true;
      }
    }

    if (errorObject is HttpError) {
      if ((errorObject as HttpError).statusCode == 401) {
        return true;
      }
    }

    return false;
  }
}

import 'package:dio/dio.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:syncora_frontend/core/data/enums/app_error_code.dart';

class ErrorMapper {
  static AppErrorCode mapError(Object e) {
    if (e is DioException) return _mapDioError(e);

    return AppErrorCode.UNKNOWN;
  }

  static String parseLogMessage(
      String message, StackTrace stacktrace, StackTrace currentStackTrace) {
    final origin = _parseStackTrace(stacktrace).toString().trim();
    final current = _parseStackTrace(currentStackTrace).toString().trim();

    return '''
      $message

      ── Origin (where it was thrown) ──────────────────

      $origin



      ── Caught at (your code) ─────────────────────────

      $current
        '''
        .trim();
  }

  static StackTrace _parseStackTrace(StackTrace stackTrace) {
    // return stackTrace;
    return Trace.from(stackTrace).foldFrames((p0) =>
        p0.toString().contains("dart-sdk") ||
        p0.toString().contains("flutter") ||
        p0.toString().contains("riverpod") ||
        p0.toString().contains("dart:ui"));
  }

  static AppErrorCode _mapDioError(DioException e) {
    // If the response comes with an error code we parse it
    String? errorCode = e.response?.data["code"];
    AppErrorCode? errorCodeEnum = AppErrorCode.values
        .where((element) => element.name == errorCode)
        .firstOrNull;

    if (errorCodeEnum != null) {
      return errorCodeEnum;
    }
    // If it does not, we parse the exception type
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return AppErrorCode.DIO_CONNECTION_TIMEOUT;
      case DioExceptionType.sendTimeout:
        return AppErrorCode.DIO_SEND_TIMEOUT;
      case DioExceptionType.receiveTimeout:
        return AppErrorCode.DIO_RECEIVE_TIMEOUT;
      case DioExceptionType.badCertificate:
        return AppErrorCode.DIO_BAD_CERTIFICATE;
      case DioExceptionType.cancel:
        return AppErrorCode.DIO_REQUEST_CANCELLED;
      case DioExceptionType.connectionError:
        return AppErrorCode.DIO_CONNECTION_ERROR;
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        return switch (code) {
          400 => AppErrorCode.HTTP_BAD_REQUEST,
          401 => AppErrorCode.HTTP_UNAUTHORIZED,
          403 => AppErrorCode.HTTP_FORBIDDEN,
          404 => AppErrorCode.HTTP_NOT_FOUND,
          408 => AppErrorCode.HTTP_REQUEST_TIMEOUT,
          422 => AppErrorCode.HTTP_UNPROCESSABLE,
          429 => AppErrorCode.HTTP_TOO_MANY_REQUESTS,
          _ => AppErrorCode.HTTP_UNEXPECTED,
        };
      case DioExceptionType.unknown:
        return AppErrorCode.UNKNOWN;
    }

    // static String _localizeServerErrorCode(ServerErrorCodes code) {
    //   switch (code) {
    //     case ServerErrorCodes.GROUP_NOT_FOUND:
    //       return AppLocalizations.of(context).groupNotFound;
    //     case ServerErrorCodes.GROUP_DETAILS_UNCHANGED:
    //       return "Group details unchanged";
    //     case ServerErrorCodes.TASK_NOT_FOUND:
    //       return "Task not found";
    //     case ServerErrorCodes.ACCESS_DENIED:
    //       return "Access denied";
    //     case ServerErrorCodes.OWNER_CANNOT_PERFORM_ACTION:
    //       return "Owner cannot perform action";
    //     case ServerErrorCodes.SHARED_USER_CANNOT_PERFORM_ACTION:
    //       return "Shared user cannot perform action";
    //     case ServerErrorCodes.USER_NOT_FOUND:
    //       return "User not found";
    //     case ServerErrorCodes.USER_ALREADY_VERIFIED:
    //       return "User already verified";
    //     case ServerErrorCodes.USER_NOT_ASSIGNED_TO_TASK:
    //       return "User not assigned to task";
    //     case ServerErrorCodes.INVALID_URL:
    //       return "Invalid URL";
    //     case ServerErrorCodes.INVALID_CREDENTIALS:
    //       return "Invalid credentials";
    //     case ServerErrorCodes.EMAIL_ALREADY_IN_USE:
    //       return "Email already in use";
    //     case ServerErrorCodes.USERNAME_ALREADY_IN_USE:
    //       return "Username already in use";
    //     case ServerErrorCodes.CREDENTIALS_ALREADY_IN_USE:
    //       return "Credentials already in use";
    //     case ServerErrorCodes.INVALID_TOKEN:
    //       return "Invalid token";
    //     case ServerErrorCodes.INVALID_GOOGLE_TOKEN:
    //       return "Invalid Google token";
    //     case ServerErrorCodes.USER_ALREADY_GRANTED:
    //       return "User already granted";
    //     case ServerErrorCodes.USER_ALREADY_REVOKED:
    //       return "User already revoked";
    //     case ServerErrorCodes.NO_USERNAMES_PROVIDED:
    //       return "No usernames provided";
    //     case ServerErrorCodes.INTERNAL_ERROR:
    //       return "Internal error";
    //     case ServerErrorCodes.EMAIL_SEND_FAILED:
    //       return "Email send failed";
    //     case ServerErrorCodes.UNKNOWN:
    //       return "Unknown error";
    //   }
  }
}

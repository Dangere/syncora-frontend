import 'dart:async';

import 'package:dio/dio.dart';

class ErrorMapper {
  static String map(Object e) {
    if (e is DioException) {
      return mapDioError(e);
    }

    if (e is TimeoutException) {
      return "Time out error occurred, no response for ${e.duration?.inSeconds ?? "few"} seconds";
    }

    if (e is Exception) {
      return "Internal error: ${e.toString()}";
    }

    return "Unknown error: ${e.toString()}";
  }

  static String mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return "Connection timed out. Please check your internet and try again.";
      case DioExceptionType.sendTimeout:
        return "Request timeout: failed to send data. Please try again.";
      case DioExceptionType.receiveTimeout:
        return "Server is taking too long to respond. Please try again later.";
      case DioExceptionType.badCertificate:
        return "Certificate error—unable to verify server. Please try again on a secure network.";
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        if (code == 429) return "Too many requests, please try again later.";

        // if (code == 401) return "Unauthorized: Invalid credentials.";
        // if (code >= 500) return "Server error ($code), ${e.response}";
        if (code >= 400) return "${e.response}";
        return "Unexpected status code: $code";
      case DioExceptionType.cancel:
        return "Request was cancelled. Please try again if you need to.";
      case DioExceptionType.connectionError:
        return "Network error: Unable to reach server. Check your connection.";
      case DioExceptionType.unknown:
      default:
        return "Unexpected error occurred. Please try again later.";
    }
  }
}

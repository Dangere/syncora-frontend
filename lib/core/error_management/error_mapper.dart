import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:source_map_stack_trace/source_map_stack_trace.dart';
import 'package:source_maps/parser.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:syncora_frontend/core/error_management/app_error_code.dart';

class ErrorMapper {
  static Map<String, dynamic>? _sourceMap;

  static Future initializeSourceMap() async {
    if (!kIsWeb) return;

    try {
      if (!kReleaseMode) {
        // final raw =
        //     await rootBundle.loadString('assets/source_map/main.dart.js.map');
        // _sourceMap = jsonDecode(raw) as Map<String, dynamic>;
      } else {
        final response = await Dio().get('/main.dart.js.map');
        _sourceMap = jsonDecode(response.data) as Map<String, dynamic>;
      }
    } catch (e) {
      _sourceMap = null;
    }
  }

  static AppErrorCode mapError(Object e) {
    if (e is DioException) return _mapDioError(e);

    if (e is TimeoutException) return AppErrorCode.DIO_SEND_TIMEOUT;

    return AppErrorCode.UNKNOWN;
  }

  static String parseLogMessage(
      String message, StackTrace stacktrace, StackTrace currentStackTrace) {
    final origin = _parseStackTrace(stacktrace).toString().trim();
    final current = _parseStackTrace(currentStackTrace).toString().trim();

    return '''
      $message

      ── Origin (where it was thrown) ──

      $origin



      ── Caught at (your code) ──

      $current
        '''
        .trim();
  }

  static StackTrace _parseStackTrace(StackTrace stackTrace) {
    if (_sourceMap != null) {
      stackTrace = mapStackTrace(parseJson(_sourceMap!), stackTrace);
    }
    return Trace.from(stackTrace).foldFrames((p0) =>
        p0.toString().contains("dart-sdk") ||
        p0.toString().contains("flutter") ||
        p0.toString().contains("riverpod") ||
        p0.toString().contains("dart:ui"));
  }

  static AppErrorCode _mapDioError(DioException e) {
    // If the response comes with an error code we parse it
    var data = e.response?.data;
    var code = data is Map ? data['code'] : null;
    String? errorCode = code is String ? code : null;
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
  }
}

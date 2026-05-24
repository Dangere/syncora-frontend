import 'dart:async';

import 'package:dio/dio.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/tokens.dart';

class AuthInterceptor extends Interceptor {
  final Tokens? Function() _tokens;
  final Future<Result> Function() _refreshTokens;
  final Dio _dio; // The main Dio instance

  // Completer? _refreshTokenCompleter;

  AuthInterceptor(
      {required Tokens? Function() tokens,
      required Future<Result> Function() refreshTokens,
      required Dio dio})
      : _refreshTokens = refreshTokens,
        _dio = dio,
        _tokens = tokens;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_tokens()?.accessToken != null) {
      options.headers['Authorization'] = 'Bearer ${_tokens()!.accessToken}';
    }

    // ref.read(loggerProvider).i("Dio request: ${options.data}");

    super.onRequest(options, handler);
  }

  // TODO: This needs rework as it can lead to an aggressive infinite loop of requests leading to rate limiting
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // ref.read(loggerProvider).i("Dio Error: ${err.response?.statusCode}");

    int? status = err.response?.statusCode;
    bool haveAccessToken = _tokens() != null;

    // If we have an access token and the error is 401 unauthorized
    if (haveAccessToken && status == 401) {
      // 1. We get a new access token based on the refresh token
      Result refreshTokenResult = await _refreshTokens().timeout(
          const Duration(seconds: 10),
          onTimeout: () =>
              Result.canceled("Token Refresh Timeout", StackTrace.current));

      if (!refreshTokenResult.isSuccess) {
        if (refreshTokenResult.error!.exception is DioException) {
          return super.onError(
              refreshTokenResult.error!.exception as DioException, handler);
        }
        return super.onError(err, handler);
      } else {
        // 2. Retry the failed request
        Result<Response> responseResult = await _retryRequest(err, handler);
        // 3. If it failed for whatever reason we return the error
        if (!responseResult.isSuccess) {
          return super.onError(err, handler);
        }

        return handler.resolve(responseResult.data!);
      }
    }
    super.onError(err, handler);
  }

  Future<Result<Response>> _retryRequest(
      DioException err, ErrorInterceptorHandler handler) async {
    try {
      final options = err.requestOptions;
      // Making sure we are updating the authorization header with the current access token
      options.headers['Authorization'] = 'Bearer ${_tokens()!.accessToken}';

      // Retrying the request
      final response =
          await _dio.fetch(options).timeout(const Duration(seconds: 10));
      return Result.success(response);
    } catch (e, stackTrace) {
      return Result.failureError(e, stackTrace);
    }
  }
}

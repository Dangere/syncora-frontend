import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/features/authentication/services/session_storage.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';

class AuthInterceptor extends Interceptor {
  final SessionStorage _sessionStorage;
  final Ref ref;
  final Dio _dio; // The main Dio instance

  Completer? _refreshTokenCompleter;

  AuthInterceptor(
      {required SessionStorage sessionStorage,
      required this.ref,
      required Dio dio})
      : _sessionStorage = sessionStorage,
        _dio = dio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_sessionStorage.accessToken != null) {
      options.headers['Authorization'] =
          'Bearer ${_sessionStorage.accessToken}';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // If we have an access token and the error is 401 unauthorized

    ref.read(loggerProvider).d("Error: ${err.response?.statusCode}");

    int? status = err.response?.statusCode;
    bool haveAccessToken = _sessionStorage.accessToken != null;

    if (haveAccessToken && status == 401) {
      try {
        if (_refreshTokenCompleter != null) {
          // If the refresh token is already in progress, wait for it to complete
          await _refreshTokenCompleter!.future;

          // If we dont have a refresh token after waiting, it means user was logged out and tokens were cleared so we end all pending requests
          if (_sessionStorage.refreshToken == null) {
            return super.onError(err, handler);
          }

          // Retry the failed request with the new access token
          Response response = await _retryRequest(err, handler);
          return handler.resolve(response);
        } else {
          _refreshTokenCompleter = Completer();
          // 1. We get a new access token based on the refresh token
          await ref.read(authNotifierProvider.notifier).refreshTokens();
          _refreshTokenCompleter!.complete();

          // 2. Retry the failed request
          Response response = await _retryRequest(err, handler);
          return handler.resolve(response);
        }
      } on DioException catch (e) {
        if (!_refreshTokenCompleter!.isCompleted) {
          _refreshTokenCompleter!.completeError(e);
        }

        return super.onError(e,
            handler); // Propagate the new error returned from refreshing tokens
      } finally {
        _refreshTokenCompleter = null;
      }
    }
    super.onError(err, handler);
  }

  Future<Response> _retryRequest(
      DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    // Making sure we are updating the authorization header with the current access token
    options.headers['Authorization'] = 'Bearer ${_sessionStorage.accessToken}';

    // Retrying the request
    final response = await _dio.fetch(options);
    return response;
  }
}

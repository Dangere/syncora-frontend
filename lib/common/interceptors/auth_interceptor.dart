import 'package:dio/dio.dart';
import 'package:syncora_frontend/features/authentication/services/session_storage.dart';

class AuthInterceptor extends Interceptor {
  final SessionStorage _sessionStorage;
  AuthInterceptor({required SessionStorage sessionStorage})
      : _sessionStorage = sessionStorage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_sessionStorage.token == null) return super.onRequest(options, handler);

    options.headers['Authorization'] = 'Bearer ${_sessionStorage.token}';
    super.onRequest(options, handler);
  }
}

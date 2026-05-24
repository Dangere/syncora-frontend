import 'package:dio/dio.dart';

class ConnectionInterceptor extends Interceptor {
  final bool Function() _isOnline;

  ConnectionInterceptor(bool Function() isOnline) : _isOnline = isOnline;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_isOnline()) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'No internet connection',
        ),
        true, // calls onError interceptors
      );
      return;
    }

    super.onRequest(options, handler);
  }
}

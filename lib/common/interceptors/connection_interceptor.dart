import 'package:dio/dio.dart';

class ConnectionInterceptor extends Interceptor {
  final bool Function() _isOnlineFactory;

  ConnectionInterceptor(bool Function() isOnlineFactory)
      : _isOnlineFactory = isOnlineFactory;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_isOnlineFactory()) {
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

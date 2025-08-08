import 'package:dio/dio.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/features/authentication/services/session_storage.dart';

class AuthInterceptor extends Interceptor {
  final SessionStorage _sessionStorage;
  AuthInterceptor({required SessionStorage sessionStorage})
      : _sessionStorage = sessionStorage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_sessionStorage.accessToken == null) {
      return super.onRequest(options, handler);
    }

    options.headers['Authorization'] = 'Bearer ${_sessionStorage.accessToken}';
    super.onRequest(options, handler);
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_sessionStorage.accessToken == null) {
      return super.onError(err, handler);
    }
    // The access token is invalid
    if (err.response?.statusCode == 401) {
      // We get a new access token based on the refresh token
// handler.resolve( )
    }

    super.onError(err, handler);
  }

  Future<void> refreshAccessToken() async {
    Dio dio = Dio();

    final response = await dio
        .post("${Constants.BASE_API_URL}/authentication/refresh-token", data: {
      "RefreshToken": _sessionStorage.refreshToken,
      "AccessToken": _sessionStorage.accessToken
    }).timeout(const Duration(seconds: 10));
  }
}

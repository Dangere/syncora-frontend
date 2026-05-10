import 'package:dio/dio.dart';
import 'package:syncora_frontend/core/analytics/breadcrumb_type.dart';
import 'package:syncora_frontend/core/analytics/breadcrumbs_service.dart';

class BreadcrumbInterceptor extends Interceptor {
  BreadcrumbInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    BreadcrumbService.instance
        .add(BreadcrumbType.network, "${options.method}: ${options.uri.path}");
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    BreadcrumbService.instance.add(BreadcrumbType.network,
        "SUCCESS: ${response.realUri.path}: ${response.statusCode}");

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    BreadcrumbService.instance.add(BreadcrumbType.network,
        "FAIL: ${err.response?.realUri.path}: ${err.response?.statusCode}, message: ${err.response}");

    super.onError(err, handler);
  }
}

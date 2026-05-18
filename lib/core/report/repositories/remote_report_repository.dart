import 'package:dio/dio.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/core/report/report.dart';

class RemoteReportRepository {
  final Dio _dio;

  RemoteReportRepository({required Dio dio}) : _dio = dio;

  Future<void> submitErrorReport(Report report) async {
    await _dio
        .post('${Constants.BASE_API_URL}/report/error', data: report.toJson())
        .timeout(const Duration(seconds: 10));
  }

  Future<void> submitBugReport(Report report) async {
    await _dio
        .post('${Constants.BASE_API_URL}/report/bug', data: report.toJson())
        .timeout(const Duration(seconds: 10));
  }
}

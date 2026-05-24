import 'package:syncora_frontend/core/analytics/breadcrumb.dart';
import 'package:syncora_frontend/core/analytics/diagnostics_service.dart';
import 'package:syncora_frontend/core/error_management/app_error.dart';
import 'package:syncora_frontend/core/error_management/app_error_code.dart';
import 'package:syncora_frontend/core/report/report.dart';
import 'package:syncora_frontend/core/report/report_type.dart';
import 'package:syncora_frontend/core/report/repositories/local_report_repository.dart';
import 'package:syncora_frontend/core/network/outbox/model/enqueue_request.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/report/repositories/remote_report_repository.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/users/models/user.dart';

/// Used to create and enqueue bug reports and error reports
class ReportService {
  final LocalReportRepository _localReportRepository;
  final RemoteReportRepository _remoteReportRepository;

  final DiagnosticsService _diagnosticsService;
  final Future<Result<User?>> Function() _user;

  final AsyncFunc<EnqueueRequest, Result<void>> _enqueueEntry;
  final List<Breadcrumb> Function() _crumbs;

  ReportService(this._localReportRepository, this._remoteReportRepository,
      this._diagnosticsService,
      {required Future<Result<void>> Function(EnqueueRequest) enqueueEntry,
      required List<Breadcrumb> Function() crumbs,
      required Future<Result<User?>> Function() user})
      : _user = user,
        _enqueueEntry = enqueueEntry,
        _crumbs = crumbs;

  /// Used to create a bug report and enqueue it
  Future<Result<void>> reportBug(String userMessage) async {
    Report report = await _generateReport(
        type: ReportType.bug, message: userMessage, manualReport: true);

    Result enqueueResult = await _enqueueEntry(EnqueueRequest(
      entry: OutboxEntry.entry(
        requiresAuthentication: false,
        entityId: report.id,
        entityType: OutboxEntityType.report,
        actionType: OutboxActionType.create,
        payload: null,
      ),
      onAfterEnqueue: () async {
        try {
          await _localReportRepository.insertReport(report);
          return Result.success();
        } catch (e, stackTrace) {
          return Result.failureError(e, stackTrace);
        }
      },
    ));
    if (!enqueueResult.isSuccess && !enqueueResult.isCancelled) {
      return Result.failureFrom(enqueueResult);
    }

    return Result.success();
  }

  /// Creates a report and enqueues it
  ///
  /// This gets called automatically when an exception is thrown
  Future<Result<void>> reportError(AppError error) async {
    // TODO: we could make other reports be saved locally incase a user error gets triggered but in the wrong circumstances
    // so we can let the user issue a bug report and select that report
    if (error.errorCode != AppErrorCode.UNKNOWN) {
      return Result.canceled(
          "reporting a none random exception canceled", StackTrace.current);
    }

    Report report = await _generateReport(
        type: ReportType.error,
        message: "Code:${error.errorCode.name} Log: ${error.logMessage}",
        manualReport: false);

    Result enqueueResult = await _enqueueEntry(EnqueueRequest(
      entry: OutboxEntry.entry(
        requiresAuthentication: false,
        entityId: report.id,
        entityType: OutboxEntityType.report,
        actionType: OutboxActionType.create,
        payload: null,
      ),
      onAfterEnqueue: () async {
        try {
          await _localReportRepository.insertReport(report);
          return Result.success();
        } catch (e, stackTrace) {
          return Result.failureError(e, stackTrace);
        }
      },
    ));
    if (!enqueueResult.isSuccess && !enqueueResult.isCancelled) {
      return Result.failureFrom(enqueueResult);
    }

    return Result.success();
  }

  /// This works like the reportError function but does not enqueue and does not save the report
  ///
  /// This gets called manually when an exception is thrown and displayed to the user
  Future<Result<void>> reportFetalError(AppError error) async {
    Report report = await _generateReport(
        type: ReportType.error,
        message: "Code:${error.errorCode.name} Log: ${error.logMessage}",
        manualReport: true);

    return _submitReportDirectly(report);
  }

  /// This gets used when an error fails to be sent to backend for whatever reason using the reportError() method
  Future<Result<void>> manuallySubmitReport(
      int reportId, AppError cause) async {
    try {
      Report report = await _localReportRepository.getReport(reportId);

      report.failedToReport(cause.logMessage);

      return _submitReportDirectly(report);
    } catch (e, stackTrace) {
      return Result.failureError(e, stackTrace);
    }
  }

  /// Generates a report
  Future<Report> _generateReport(
      {required ReportType type,
      required String message,
      required bool manualReport}) async {
    Result<User?> user = await _user();

    Map<String, dynamic> userSession = user.data == null
        ? {"emptySession": true, "failed": !user.isSuccess}
        : user.data!.toJson();

    return Report(
        id: DateTime.now().millisecondsSinceEpoch,
        type: type,
        message: message,
        appVersion: _diagnosticsService.appVersion,
        platform: _diagnosticsService.platform,
        osVersion: _diagnosticsService.osVersion,
        breadcrumbs: _crumbs().map((e) => e.toJson()).toList(),
        deviceModel: _diagnosticsService.deviceModel,
        locale: _diagnosticsService.locale,
        userSession: userSession,
        appState: {"manualReport": manualReport});
  }

  /// Submits a report directly
  Future<Result<void>> _submitReportDirectly(Report report) async {
    try {
      await _remoteReportRepository.submitErrorReport(report);
    } catch (e, stackTrace) {
      return Result.failureError(e, stackTrace);
    }
    return Result.success();
  }
}

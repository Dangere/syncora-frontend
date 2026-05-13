import 'dart:convert';

import 'package:syncora_frontend/core/analytics/breadcrumb.dart';
import 'package:syncora_frontend/core/analytics/diagnostics_service.dart';
import 'package:syncora_frontend/core/error_management/app_error.dart';
import 'package:syncora_frontend/core/error_management/app_error_code.dart';
import 'package:syncora_frontend/core/report/report.dart';
import 'package:syncora_frontend/core/report/report_type.dart';
import 'package:syncora_frontend/core/report/repositories/local_report_repository.dart';
import 'package:syncora_frontend/core/network/outbox/model/enqueue_request.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/session.dart';

class ReportService {
  final LocalReportRepository _localReportRepository;

  final DiagnosticsService _diagnosticsService;
  final Session Function() _sessionFactory;

  final AsyncFunc<EnqueueRequest, Result<void>> _enqueueEntry;
  final List<Breadcrumb> Function() _crumbs;

  ReportService(this._localReportRepository, this._diagnosticsService,
      {required Future<Result<void>> Function(EnqueueRequest) enqueueEntry,
      required List<Breadcrumb> Function() crumbs,
      required Session Function() sessionFactory})
      : _sessionFactory = sessionFactory,
        _enqueueEntry = enqueueEntry,
        _crumbs = crumbs;

  Future<Result<void>> reportError(AppError error) async {
    // TODO: we could make other reports be saved locally incase a user error gets triggered but in the wrong circumstances
    // so we can let the user issue a bug report and select that report
    if (error.errorCode != AppErrorCode.UNKNOWN) {
      return Result.canceled(
          "reporting a none random exception canceled", StackTrace.current);
    }

    Report report = Report(
        id: DateTime.now().millisecondsSinceEpoch,
        type: ReportType.error,
        message: error.errorCode.name + ": " + error.logMessage,
        appVersion: _diagnosticsService.appVersion,
        platform: _diagnosticsService.platform,
        osVersion: _diagnosticsService.osVersion,
        breadcrumbs: _crumbs().map((e) => e.toJson()).toList(),
        deviceModel: _diagnosticsService.deviceModel,
        locale: _diagnosticsService.locale,
        userSession: _sessionFactory().toJson(),
        appState: {"lelele?": "pep"});

    // Create an encoder with a 2-space indent

    // Convert and print
    String prettyPrint =
        const JsonEncoder.withIndent('  ').convert(report.toJson());
    print(prettyPrint);

    // Result enqueueResult = await _enqueueEntry(EnqueueRequest(
    //   entry: OutboxEntry.entry(
    //     entityId: report.id,
    //     entityType: OutboxEntityType.report,
    //     actionType: OutboxActionType.create,
    //     payload: null,
    //   ),
    //   onAfterEnqueue: () async {
    //     try {
    //       await _localReportRepository.insertReport(report);
    //       return Result.success();
    //     } catch (e, stackTrace) {
    //       return Result.failureError(e, stackTrace);
    //     }
    //   },
    // ));
    // if (!enqueueResult.isSuccess && !enqueueResult.isCancelled) {
    //   return Result.failureFrom(enqueueResult);
    // }

    return Result.success();
  }
}

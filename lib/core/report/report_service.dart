import 'package:syncora_frontend/core/analytics/breadcrumb.dart';
import 'package:syncora_frontend/core/analytics/diagnostics_service.dart';
import 'package:syncora_frontend/core/report/report.dart';
import 'package:syncora_frontend/core/report/report_type.dart';
import 'package:syncora_frontend/core/report/repositories/local_report_repository.dart';
import 'package:syncora_frontend/core/network/outbox/model/enqueue_request.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/core/utils/result.dart';

class ReportService {
  final LocalReportRepository _localReportRepository;

  final DiagnosticsService _diagnosticsService;

  final AsyncFunc<EnqueueRequest, Result<void>> _enqueueEntry;
  final List<Breadcrumb> Function() _crumbs;

  ReportService(this._localReportRepository, this._diagnosticsService,
      {required Future<Result<void>> Function(EnqueueRequest) enqueueEntry,
      required List<Breadcrumb> Function() crumbs})
      : _enqueueEntry = enqueueEntry,
        _crumbs = crumbs;

  Future<Result<void>> reportError(Object e) async {
    var breadcrumbs = _crumbs();

    Report report = Report(
        id: DateTime.now().millisecondsSinceEpoch,
        type: ReportType.error,
        message: e.toString(),
        appVersion: _diagnosticsService.appVersion,
        platform: _diagnosticsService.platform,
        osVersion: _diagnosticsService.osVersion,
        breadcrumbs: breadcrumbs.map((e) => e.toJson()).toList(),
        deviceModel: _diagnosticsService.deviceModel,
        locale: _diagnosticsService.locale,
        userSession: {"Logged in ?": "yesssss"},
        appState: {"lelele?": "pep"});

    Result enqueueResult = await _enqueueEntry(EnqueueRequest(
      entry: OutboxEntry.entry(
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
}

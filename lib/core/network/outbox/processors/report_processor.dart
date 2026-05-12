import 'package:syncora_frontend/core/report/report.dart';
import 'package:syncora_frontend/core/report/repositories/local_report_repository.dart';
import 'package:syncora_frontend/core/network/outbox/exception/outbox_exception.dart';
import 'package:syncora_frontend/core/network/outbox/interface/outbox_processor_interface.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/report/repositories/remote_report_repository.dart';

class ReportProcessor extends OutboxProcessor {
  final LocalReportRepository _localReportRepository;
  final RemoteReportRepository _remoteReportRepository;

  ReportProcessor(super.idMapper, super.logger, this._localReportRepository,
      this._remoteReportRepository);

  @override
  Future<int> processToBackend(OutboxEntry entry) async {
    switch (entry.actionType) {
      case OutboxActionType.create:
        {
          Report report =
              await _localReportRepository.getReport(entry.entityId);

          print(report.toJson());
          await _localReportRepository.updateReportToSent(entry.entityId);
          print(report.toJson());

          // _remoteReportRepository.sendErrorReport(report: report);
        }

        break;

      default:
        throw OutboxException("Unsupported action type: ${entry.toTable()}");
    }

    return entry.entityId;
  }

  @override
  Future<int> revertLocalChange(OutboxEntry entry) async {
    switch (entry.actionType) {
      case OutboxActionType.create:
        break;

      default:
        throw OutboxException("Unsupported action type: ${entry.toTable()}");
    }
    return entry.entityId;
  }
}

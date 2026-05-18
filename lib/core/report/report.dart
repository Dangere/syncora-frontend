import 'dart:convert';

import 'package:syncora_frontend/core/report/report_type.dart';

class Report {
  final int id;
  final ReportType type;
  late final DateTime creationDate;
  final String message;
  final String appVersion;
  final String platform;
  final String osVersion;
  final String deviceModel;
  final String locale;
  final Map<String, dynamic> userSession;
  final Map<String, dynamic> appState;
  final List<Map<String, dynamic>> breadcrumbs;

  late final bool isSent;

  Report(
      {required this.id,
      required this.message,
      required this.appVersion,
      required this.platform,
      required this.osVersion,
      required this.breadcrumbs,
      required this.deviceModel,
      required this.locale,
      required this.userSession,
      required this.appState,
      required this.type,
      creationDate,
      isSent}) {
    if (creationDate == null) {
      this.creationDate = DateTime.now().toUtc();
    } else {
      this.creationDate = creationDate;
    }

    if (isSent == null) {
      this.isSent = false;
    } else {
      this.isSent = isSent;
    }
  }

  void failedToReport(String reason) {
    appState['reportFailureToSend'] = true;
    appState['reportFailureReason'] = reason;
    appState['manualReport'] = true;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'message': message,
      'appVersion': appVersion,
      'platform': platform,
      'osVersion': osVersion,
      'deviceModel': deviceModel,
      'locale': locale,
      'userSession': userSession,
      'appState': appState,
      'breadcrumbs': breadcrumbs,
      'creationDate': creationDate.toIso8601String(),
    };
  }

  Map<String, dynamic> toTable() {
    return {
      'id': id,
      'type': type.index,
      'message': message,
      'appVersion': appVersion,
      'platform': platform,
      'osVersion': osVersion,
      'deviceModel': deviceModel,
      'locale': locale,
      'userSession': jsonEncode(userSession),
      'appState': jsonEncode(appState),
      'breadcrumbs': jsonEncode(breadcrumbs),
      'creationDate': creationDate.toIso8601String(),
      'isSent': isSent ? 1 : 0
    };
  }

  factory Report.fromTable(Map<String, dynamic> row) {
    return Report(
        id: row['id'] as int,
        type: ReportType.values[row['type'] as int],
        message: row['message'] as String,
        appVersion: row['appVersion'] as String,
        platform: row['platform'] as String,
        osVersion: row['osVersion'] as String,
        deviceModel: row['deviceModel'] as String,
        locale: row['locale'] as String,
        userSession:
            jsonDecode(row['userSession'] as String) as Map<String, dynamic>,
        appState: jsonDecode(row['appState'] as String) as Map<String, dynamic>,
        breadcrumbs: List<Map<String, dynamic>>.from(
            jsonDecode(row['breadcrumbs'] as String)),
        creationDate: DateTime.parse(row['creationDate'] as String),
        isSent: row['isSent'] == 1 ? true : false);
  }
}

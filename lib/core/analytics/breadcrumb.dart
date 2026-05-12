import 'package:syncora_frontend/core/analytics/breadcrumb_type.dart';

class Breadcrumb {
  final BreadcrumbType type;
  final String context;
  final DateTime timestamp = DateTime.now().toUtc();
  late final int sinceLastCrumbMilliseconds;

  Breadcrumb(this.type, this.context, {Breadcrumb? previousCrumb}) {
    if (previousCrumb == null) {
      sinceLastCrumbMilliseconds = 0;
    } else {
      Duration diff = timestamp.difference(previousCrumb.timestamp);

      sinceLastCrumbMilliseconds = diff.inMilliseconds;
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.name,
        'context': context,
        'timestamp': timestamp.toIso8601String(),
        'afterMs': sinceLastCrumbMilliseconds
      };
}

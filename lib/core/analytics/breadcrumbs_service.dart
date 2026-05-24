import 'dart:async';

import 'package:syncora_frontend/core/analytics/breadcrumb.dart';
import 'package:syncora_frontend/core/analytics/breadcrumb_type.dart';

/// Breadcrumb service used to keep track of the breadcrumbs and send them to the backend
class BreadcrumbService {
  BreadcrumbService._();
  static final instance = BreadcrumbService._();

  final List<Breadcrumb> _crumbs = [];
  final StreamController<Breadcrumb> _controller =
      StreamController<Breadcrumb>.broadcast();

  /// Returns the list of breadcrumbs
  List<Breadcrumb> get getCrumbs => List.unmodifiable(_crumbs);

  /// Returns the stream of breadcrumbs to update the UI that listens to it (manually just for a debugging logic purposes)
  Stream<Breadcrumb> get crumbStream => _controller.stream;

  /// The maximum number of breadcrumbs to keep
  final int maxCrumbs = 20;

  /// Adds a new breadcrumb
  void add(BreadcrumbType type, String context) {
    Breadcrumb crumb =
        Breadcrumb(type, context, previousCrumb: _crumbs.lastOrNull);

    if (_controller.hasListener) _controller.add(crumb);
    _crumbs.add(crumb);

    if (_crumbs.length > maxCrumbs) {
      _crumbs.removeAt(0);
    }
  }
}

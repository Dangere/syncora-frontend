import 'dart:async';

import 'package:syncora_frontend/core/analytics/breadcrumb.dart';
import 'package:syncora_frontend/core/analytics/breadcrumb_type.dart';

class BreadcrumbService {
  BreadcrumbService._();
  static final instance = BreadcrumbService._();

  final List<Breadcrumb> _crumbs = [];
  final StreamController<Breadcrumb> _controller =
      StreamController<Breadcrumb>.broadcast();

  List<Breadcrumb> get getCrumbs => List.unmodifiable(_crumbs);
  Stream<Breadcrumb> get crumbStream => _controller.stream;

  final int maxCrumbs = 20;

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

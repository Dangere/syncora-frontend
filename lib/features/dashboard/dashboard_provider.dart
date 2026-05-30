import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';

/// Provider to determine if the dashboard alert should be displayed, it gets displayed once per session
final displayDashboardAlertProvider = Provider<bool>((ref) {
  const String displayedAlertKey = "displayed_dashboard_alert";

  bool? didDisplayAlert =
      ref.read(sharedPreferencesProvider).getBool(displayedAlertKey);

  if (didDisplayAlert == null || !didDisplayAlert) {
    ref.read(sharedPreferencesProvider).setBool(displayedAlertKey, true);

    return true;
  }

  return false;
});

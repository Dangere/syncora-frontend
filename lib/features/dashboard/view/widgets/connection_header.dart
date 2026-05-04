import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/common/themes/app_spacing.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/network/syncing/sync_provider.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/dashboard/view/pages/dashboard_page.dart';

class ConnectionHeader extends ConsumerWidget {
  const ConnectionHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isOnline = ref.watch(isOnlineProvider);
    bool isConnectedToBackend = ref.watch(connectedToBackendProvider);
    bool isAuthenticated = ref.watch(isAuthenticatedProvider);

    String alertText = "";

    if (!isConnectedToBackend) {
      alertText =
          AppLocalizations.of(context).notification_Backend_Disconnected;
    }

    if (!isOnline) {
      alertText = AppLocalizations.of(context).notification_Online_Disconnected;
    }

    bool displayAlert = (!isOnline || !isConnectedToBackend) && isAuthenticated;

    return SliverPersistentHeader(
        delegate: MySliverPersistentHeaderDelegate(
            child: Center(
              child: AnimatedContainer(
                color: displayAlert
                    ? Colors.grey.withValues(alpha: .40)
                    : Colors.transparent,
                duration: const Duration(milliseconds: 200),
                child: displayAlert
                    ? Center(
                        child: Text(alertText),
                      )
                    : const SizedBox(
                        height: AppSpacing.xl,
                      ),
              ),
            ),
            height: AppSpacing.xl),
        pinned: displayAlert);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/widgets/app_button.dart';
import 'package:syncora_frontend/core/error_management/app_error.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/localization/localize_app_errors.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_provider.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';

class FetalErrorPage extends ConsumerWidget {
  const FetalErrorPage({super.key, required this.error});

  final AppError error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void restart() {
      ref.read(localDbProvider).ensureDeleted();
      ref.read(outboxProvider.notifier).dispose();
      Future.microtask(
        () {
          ref.read(authProvider.notifier).logout();
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("FETAL ERROR")),
      body: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * .1,
              child: Center(
                child: Text(LocalizeAppErrors.localizeErrorCode(
                    error.errorCode, context)),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * .5,
              child: SingleChildScrollView(child: Text(error.logMessage)),
            ),
            Expanded(
              child: Center(
                child: AppButton(
                    breadcrumbLabel: () => "Restarting app",
                    size: AppButtonSize.huge,
                    style: AppButtonStyle.filled,
                    intent: AppButtonIntent.destructive,
                    onPressed: restart,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLocalizations.of(context).restart),
                        const Icon(
                          Icons.restart_alt_outlined,
                          size: 26,
                        ),
                      ],
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

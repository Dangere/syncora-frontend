import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/analytics/breadcrumbs_service.dart';
import 'package:syncora_frontend/core/error_management/app_error.dart';
import 'package:syncora_frontend/core/error_management/error_provider.dart';
import 'package:syncora_frontend/core/report/repositories/local_report_repository.dart';
import 'package:syncora_frontend/core/report/report_service.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_provider.dart';
import 'package:syncora_frontend/core/report/repositories/remote_report_repository.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/users/providers/users_provider.dart';

/// Notifier for reporting errors and bugs
class ReportNotifier extends Notifier<void> {
  Future<bool> reportError(AppError error) async {
    Result<void> result =
        await ref.read(reportServiceProvider).reportError(error);

    if (!result.isSuccess && !result.isCancelled) {
      ref.read(appErrorProvider.notifier).setReportError(null, result.error!);
    }
    return result.isSuccess;
  }

  Future<bool> reportBug(String userMessage) async {
    Result result =
        await ref.read(reportServiceProvider).reportBug(userMessage);
    if (!result.isSuccess && !result.isCancelled) {
      ref.read(appErrorProvider.notifier).setReportError(null, result.error!);
    }
    return result.isSuccess;
  }

  @override
  void build() {}
}

final reportProvider =
    NotifierProvider<ReportNotifier, void>(ReportNotifier.new);

final localReportRepositoryProvider = Provider<LocalReportRepository>((ref) {
  return LocalReportRepository(ref.read(localDbProvider));
});

final remoteReportRepositoryProvider = Provider<RemoteReportRepository>((ref) {
  return RemoteReportRepository(dio: ref.read(dioProvider));
});

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(
    ref.read(localReportRepositoryProvider),
    ref.read(remoteReportRepositoryProvider),
    ref.read(diagnosticsServiceProvider),
    enqueueEntry: (enqueueRequest) =>
        ref.read(outboxProvider.notifier).enqueue(enqueueRequest),
    crumbs: () => BreadcrumbService.instance.getCrumbs,
    user: () async {
      if (ref.read(authProvider).value?.userId == null) {
        return Result.success(null);
      }

      return ref
          .read(usersServiceProvider)
          .getCachedUser(ref.read(authProvider).value!.userId!);
    },
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/analytics/breadcrumbs_service.dart';
import 'package:syncora_frontend/core/report/repositories/local_report_repository.dart';
import 'package:syncora_frontend/core/report/report_service.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_provider.dart';
import 'package:syncora_frontend/core/report/repositories/remote_report_repository.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/users/providers/users_provider.dart';

final localReportRepositoryProvider = Provider<LocalReportRepository>((ref) {
  return LocalReportRepository(ref.read(localDbProvider));
});

final remoteReportRepositoryProvider = Provider<RemoteReportRepository>((ref) {
  return RemoteReportRepository(dio: ref.read(dioProvider));
});

final reportProvider = Provider<ReportService>((ref) {
  return ReportService(
    ref.read(localReportRepositoryProvider),
    ref.read(remoteReportRepositoryProvider),
    ref.read(diagnosticsServiceProvider),
    enqueueEntry: (enqueueRequest) =>
        ref.read(outboxProvider.notifier).enqueue(enqueueRequest),
    crumbs: () => BreadcrumbService.instance.getCrumbs,
    userFactory: () async {
      if (ref.read(authProvider).value?.userId == null) {
        return Result.success(null);
      }

      return ref
          .read(usersServiceProvider)
          .getCachedUser(ref.read(authProvider).value!.userId!);
    },
  );
});

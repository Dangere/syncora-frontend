import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/syncing/model/sync_payload.dart';
import 'package:syncora_frontend/core/syncing/sync_repository.dart';
import 'package:syncora_frontend/core/syncing/sync_service.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';

class SyncBackendNotifier extends AsyncNotifier<void> {
  late final SyncService _syncService;
  Future<void> sync() async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();
    Result<SyncPayload> result = await _syncService.syncFromServer();

    if (!result.isSuccess) {
      ref.read(appErrorProvider.notifier).state = result.error;
      state = AsyncValue.error(result.error!, StackTrace.current);

      return;
    }
    // TODO: upsert users first, then groups.
    ref.read(groupsNotifierProvider.notifier).upsertGroups(result.data!.groups);

    state = const AsyncValue.data(null);
  }

  @override
  FutureOr<void> build() {
    _syncService = ref.read(syncServiceProvider);
  }
}

final syncBackendProvider =
    AsyncNotifierProvider<SyncBackendNotifier, void>(SyncBackendNotifier.new);

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(syncRepository: ref.read(syncRepositoryProvider));
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(dio: ref.read(dioProvider));
});

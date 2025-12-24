import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/web.dart';
import 'package:syncora_frontend/core/network/syncing/sync_state.dart';
import 'package:syncora_frontend/core/network/syncing/sync_viewmodel.dart';

class SyncingIcon extends ConsumerWidget {
  const SyncingIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncBackendNotifierProvider);
    return syncState.when(
        data: (data) {
          if (data is SyncIdle) return const Icon(Icons.cloud_sync_sharp);
          if (data is SyncDisconnected) return const Icon(Icons.cloud_off);

          return const Icon(Icons.check);
        },
        error: (error, trace) {
          Logger().e(error, stackTrace: trace);
          return const Icon(Icons.error);
        },
        loading: () => const Icon(Icons.cloud_sync_sharp));
  }
}

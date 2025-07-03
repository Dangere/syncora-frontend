import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/core/network/syncing/sync_notifier.dart';

class SyncingIcon extends ConsumerWidget {
  const SyncingIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncBackendProvider);
    return syncState.when(
        data: (data) => const Icon(Icons.check),
        error: (error, trace) => const Icon(Icons.error),
        loading: () => const Icon(Icons.cloud_sync_sharp));
  }
}

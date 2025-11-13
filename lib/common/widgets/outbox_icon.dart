import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_viewmodel.dart';

class OutboxIcon extends ConsumerWidget {
  const OutboxIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(outboxProvider);
    return syncState.when(
        data: (data) => switch (data) {
              OutboxStatus.complete => const Icon(Icons.check),
              OutboxStatus.pending => const Icon(Icons.cloud_sync_sharp),
              OutboxStatus.inProcess => const Icon(Icons.cloud_sync_sharp),
              OutboxStatus.failed => const Icon(Icons.error),
            },
        error: (error, trace) {
          return const Icon(Icons.error);
        },
        loading: () => const Icon(Icons.cloud_sync_sharp));
  }
}

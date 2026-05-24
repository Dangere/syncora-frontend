import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/typedef.dart';

/// Request to enqueue into the outbox queue
class EnqueueRequest {
  /// The entry containing the entity needing to be synced and processed
  final OutboxEntry entry;

  /// Callback once the entry is confirmed to be enqueued
  final AsyncResultCallback<void>? onAfterEnqueue;

  EnqueueRequest({required this.entry, this.onAfterEnqueue});
}

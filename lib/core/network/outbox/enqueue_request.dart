import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/typedef.dart';

class EnqueueRequest {
  final OutboxEntry entry;
  final AsyncResultCallback<void>? onAfterEnqueue;

  EnqueueRequest({required this.entry, this.onAfterEnqueue});
}

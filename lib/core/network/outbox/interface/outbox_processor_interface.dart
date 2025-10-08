import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/utils/result.dart';

abstract class OutboxProcessor {
  Future<Result<void>> processOutbox(OutboxEntry entry);
}

import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/utils/result.dart';

abstract class OutboxProcessor {
  // Processes the outbox entry and returns the modified group server id
  Future<Result<int>> processOutbox(OutboxEntry entry);

  Future<Result<void>> revertProcess(OutboxEntry entry);
}

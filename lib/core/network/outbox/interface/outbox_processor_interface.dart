import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_id_mapper.dart';

abstract class OutboxProcessor {
  final OutboxIdMapper idMapper;
  final Logger logger;

  OutboxProcessor({required this.idMapper, required this.logger});

  // Processes the outbox entry and returns the modified group server id
  // Creation process should ALWAYS cache the server id when successful for future processing
  Future<int> processOutbox(OutboxEntry entry);

  // Reverts the outbox local changes and returns the modified group server id
  Future<int> revertProcess(OutboxEntry entry);
}

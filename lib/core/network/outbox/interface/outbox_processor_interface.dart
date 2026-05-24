import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_id_mapper.dart';

/// Interface used to create processors that process different types of outbox entities
abstract class OutboxProcessor {
  /// Used to either cache in temp id to server id (on entity creation) or getting ids
  final OutboxIdMapper idMapper;
  final Logger logger;

  OutboxProcessor(this.idMapper, this.logger);

  /// Processes the outbox entry and returns the modified group server id
  /// Creation process should ALWAYS cache the server id when successful for future processing
  Future<int> processToBackend(OutboxEntry entry);

  /// Reverts the outbox local changes and returns the modified group server id or temp id on group creation failure
  Future<int> revertLocalChange(OutboxEntry entry);
}

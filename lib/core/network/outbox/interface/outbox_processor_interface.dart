import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/outbox_id_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';

abstract class OutboxProcessor {
  final OutboxIdMapper idMapper;
  final Logger logger;
  final Duration delayBeforeSyncReattempt;

  OutboxProcessor(
      {required this.idMapper,
      required this.logger,
      required this.delayBeforeSyncReattempt});

  // Processes the outbox entry and returns the modified group server id
  Future<Result<int>> processOutbox(OutboxEntry entry);

  // Reverts the outbox local changes and returns the modified group server id
  Future<Result<int>> revertProcess(OutboxEntry entry);
}

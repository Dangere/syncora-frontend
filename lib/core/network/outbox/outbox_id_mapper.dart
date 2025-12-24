import 'package:syncora_frontend/core/network/outbox/repository/outbox_repository.dart';
import 'package:syncora_frontend/core/utils/result.dart';

class OutboxIdMapper {
  final Map<int, int> _cache = {};
  final OutboxRepository _outboxRepository;

  OutboxIdMapper(this._outboxRepository);

  // Returns the server id using temp generated ids
  Future<Result<int>> getServerId(int tempId) async {
    // If a tempId is not negative then its a server id
    if (tempId > 0) return Result.success(tempId);
    if (_cache.containsKey(tempId)) {
      return Result.success(_cache[tempId]!);
    }

    try {
      int serverId = await _outboxRepository.getServerId(tempId);
      _cache[tempId] = serverId;
      return Result.success(serverId);
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  /// Cache the retrieved server id to avoid unnecessary qb calls
  void cacheId({required int tempId, required int serverId}) =>
      _cache[tempId] = serverId;
}

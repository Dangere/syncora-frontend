import 'package:syncora_frontend/core/network/outbox/repository/outbox_repository.dart';

class OutboxIdMapper {
  final Map<int, int> _cache = {};
  final OutboxRepository _outboxRepository;

  OutboxIdMapper(this._outboxRepository);

  // Returns the server id using temp generated ids
  Future<int> getServerId(int tempId) async {
    // If a tempId is not negative then its a server id
    if (tempId > 0) return tempId;
    if (_cache.containsKey(tempId)) {
      return _cache[tempId]!;
    }

    int serverId = await _outboxRepository.getServerId(tempId);
    _cache[tempId] = serverId;

    return serverId;
  }

  /// Cache the retrieved server id to avoid unnecessary qb calls
  void cacheId({required int tempId, required int serverId}) =>
      _cache[tempId] = serverId;
}

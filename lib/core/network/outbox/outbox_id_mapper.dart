import 'package:syncora_frontend/core/network/outbox/repository/outbox_repository.dart';
import 'package:syncora_frontend/core/utils/result.dart';

/// Caching policy:
/// - [getServerId] does NOT cache null (entity may sync later)
/// - [getTempId] DOES cache null (entity never had a temp id — permanent)
class OutboxIdMapper {
  final Map<int, int?> _serverToTemp = {}; // serverId -> tempId
  final Map<int, int> _tempToServer = {}; // tempId -> serverId
  final OutboxRepository _outboxRepository;

  OutboxIdMapper(this._outboxRepository);

  /// Returns the server id using temp generated id, or `null` when entity not synced yet
  ///
  /// The returned value is subject to change when the entity is synced
  // On failing to fetch the server id, it returns `null` and not cache it
  Future<Result<int?>> getServerId(int tempId) async {
    // If a tempId is not negative then its a server id
    if (tempId > 0) return Result.success(tempId);

    if (_tempToServer.containsKey(tempId)) {
      return Result.success(_tempToServer[tempId]);
    }

    try {
      int? serverId = await _outboxRepository.getServerId(tempId);

      if (serverId == null) return Result.success(null);
      _cacheId(tempId: tempId, serverId: serverId);

      return Result.success(serverId);
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  /// Returns the temp id using server id if the entity was created locally then synced
  ///
  /// Otherwise if the entity was fetched from the backend it returns `null`
  ///
  /// An entity will not gain a temp id so it's not subject to change
  // On failing to fetch the temp id, it returns `null` and cache it
  Future<Result<int?>> getTempId(int serverId) async {
    // If a server id is not positive then its a temp id
    if (serverId <= 0) return Result.success(serverId);
    if (_serverToTemp.containsKey(serverId)) {
      return Result.success(_serverToTemp[serverId]);
    }

    try {
      int? tempId = await _outboxRepository.getTempId(serverId);
      _cacheId(tempId: tempId, serverId: serverId);

      return Result.success(tempId);
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  void _cacheId({required int? tempId, required int serverId}) {
    if (tempId != null) {
      _tempToServer[tempId] = serverId;
    }
    _serverToTemp[serverId] = tempId;
  }

  /// Cache the retrieved server id to temp id (when task and group are synced to backend) to avoid unnecessary db calls
  void cacheId({required int tempId, required int serverId}) {
    _tempToServer[tempId] = serverId;
    _serverToTemp[serverId] = tempId;
  }
}

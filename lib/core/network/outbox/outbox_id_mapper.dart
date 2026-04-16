import 'package:syncora_frontend/core/network/outbox/repository/outbox_repository.dart';
import 'package:syncora_frontend/core/utils/result.dart';

class OutboxIdMapper {
  final Map<int, int> _serverToTemp = {}; // serverId -> tempId
  final Map<int, int> _tempToServer = {}; // tempId -> serverId
  final OutboxRepository _outboxRepository;

  OutboxIdMapper(this._outboxRepository);

  /// If given a temp id, returns a server id, if given a server id, returns a temp id
  int? getCorrelatedId(int id) {
    if (id > 0) {
      if (_serverToTemp.containsKey(id)) {
        return _serverToTemp[id];
      }
      return null;
    } else {
      if (_tempToServer.containsKey(id)) {
        return _tempToServer[id];
      }
      return null;
    }
  }

  /// Returns in-memory cached temp id using server id if the entity was created locally then synced and cached
  ///
  /// This is used to mainly to update the UI thats listening to group notifier with a temp id using a server id
  ///
  /// This only returns ids cached in, ignoring the database state
  ///
  /// Returns null when temp id doesn't exist/cached
  int? getTempId(int serverId) {
    // If a server id is not positive then its a temp id
    if (serverId <= 0) return serverId;
    if (_serverToTemp.containsKey(serverId)) {
      return _serverToTemp[serverId];
    }

    return null;
  }

  /// Resolves an id to a server id if was cached in using the outbox system
  ///
  /// This is used to mainly to get synced id from a temp id or default to temp id
  ///
  /// This only returns ids cached in, ignoring the database state
  ///
  /// Returns the original id when temp id doesn't exist/cached
  int resolveId(int tempId) {
    if (tempId > 0) return tempId;

    if (_tempToServer.containsKey(tempId)) {
      return _tempToServer[tempId] ?? tempId;
    }

    return tempId;
  }

  /// This is used by the outbox processor to get a server id for an entity that is dependent on by an entry
  ///
  /// For example, when a temp task is being processed, it would have dependency on a group that needs to have a server id
  ///
  /// If no server id exists for that entity, it means it failed to sync in the first place and the task entity should fail automatically
  ///
  /// This uses the consistent state in the db to always have access to the server id across restarts
  Future<Result<int?>> getDependency(int tempId) async {
    // If a tempId is not negative then its a server id
    if (tempId > 0) return Result.success(tempId);

    if (_tempToServer.containsKey(tempId)) {
      return Result.success(_tempToServer[tempId]);
    }

    try {
      int? serverId = await _outboxRepository.getServerId(tempId);
      return Result.success(serverId);
    } catch (e, stackTrace) {
      return Result.failureError(e, stackTrace);
    }
  }

  /// Cache the retrieved server id to temp id (when task and group are synced to backend) to avoid unnecessary db calls
  void cacheId({required int tempId, required int serverId}) {
    _tempToServer.forEach(
      (key, value) {
        print("tempId: $key, serverId: $value");
      },
    );
    _tempToServer[tempId] = serverId;
    _serverToTemp[serverId] = tempId;
  }
}

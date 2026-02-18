import 'package:syncora_frontend/core/network/syncing/model/sync_payload.dart';

abstract class SyncState {
  const SyncState();
}

class SyncIdle extends SyncState {
  const SyncIdle();
}

class SyncAvailable extends SyncState {
  final SyncPayload payload;
  bool get isEmpty => payload.isEmpty();

  const SyncAvailable(this.payload);
}

class SyncDisconnected extends SyncState {
  const SyncDisconnected();
}

extension SyncStateX on SyncState {
  bool get isIdle => this is SyncIdle;
  bool get isAvailable => this is SyncAvailable;

  SyncPayload? get payload =>
      this is SyncAvailable ? (this as SyncAvailable).payload : null;
}

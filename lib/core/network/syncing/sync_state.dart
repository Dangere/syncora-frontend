import 'package:syncora_frontend/core/network/syncing/model/sync_payload.dart';

abstract class SyncState {
  const SyncState();
}

class SyncIdle extends SyncState {
  const SyncIdle();
}

class SyncInProgress extends SyncState {
  final SyncPayload payload;
  bool get isEmpty => payload.isEmpty();

  const SyncInProgress(this.payload);
}

class SyncDisconnected extends SyncState {
  const SyncDisconnected();
}

extension SyncStateX on SyncState {
  bool get isIdle => this is SyncIdle;
  bool get isInProgress => this is SyncInProgress;

  SyncPayload? get payload =>
      this is SyncInProgress ? (this as SyncInProgress).payload : null;
}

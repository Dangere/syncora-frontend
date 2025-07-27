abstract class SyncService {
  Stream<dynamic> get messages; // incoming events
  Future<void> start(); // open connection
  Future<void> stop(); // close connection
}

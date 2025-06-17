import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectionNotifier extends Notifier<ConnectionStatus> {
  @override
  build() {
    final connectionChecker = InternetConnectionChecker.instance;
    connectionChecker.onStatusChange.listen(
      (InternetConnectionStatus status) {
        switch (status) {
          case InternetConnectionStatus.disconnected:
            state = ConnectionStatus.disconnected;
            break;
          case InternetConnectionStatus.connected:
            state = ConnectionStatus.connected;
            break;
          case InternetConnectionStatus.slow:
            state = ConnectionStatus.slow;
            break;
          default:
        }
      },
    );
    return ConnectionStatus.checking;
  }
}

final connectionProvider =
    NotifierProvider<ConnectionNotifier, ConnectionStatus>(
        ConnectionNotifier.new);

enum ConnectionStatus { checking, connected, disconnected, slow }

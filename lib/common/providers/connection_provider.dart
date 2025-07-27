import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';

final fakeBeingOnlineProvider = StateProvider<bool>((ref) {
  return false;
});

class ConnectionNotifier extends Notifier<ConnectionStatus> {
  @override
  build() {
    ref.listen(fakeBeingOnlineProvider, (previous, next) {
      if (next) {
        state = ConnectionStatus.connected;
      } else {
        state = ConnectionStatus.disconnected;
      }
    });

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

// final connectionAsyncProvider = FutureProvider<ConnectionStatus>((ref) async {
//   ConnectionStatus currentStatus = ref.read(connectionProvider);
//   bool doneChecking = currentStatus != ConnectionStatus.checking;

//   if (!doneChecking) {
//     var sub = ref.listen(
//       connectionProvider,
//       (previous, next) async {
//         if (next != ConnectionStatus.checking) {
//           currentStatus = next;
//           doneChecking = true;
//         }
//       },
//     );
//     await Future.doWhile(() async {
//       if (!doneChecking) {
//         await Future.delayed(Durations.extralong4);
//         ref.read(loggerProvider).w("We are checking status");
//         return true;
//       } else {
//         ref.read(loggerProvider).w("We got status");
//         sub.close();
//         return false;
//       }
//     });
//   }

//   return currentStatus;
// });

enum ConnectionStatus { checking, connected, disconnected, slow }

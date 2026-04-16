import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

// ignore: non_constant_identifier_names
final debug_fakeBeingOnlineProvider = StateProvider<bool>((ref) {
  return false;
});

class ConnectionNotifier extends Notifier<ConnectionStatus> {
  @override
  build() {
    ref.listen(debug_fakeBeingOnlineProvider, (previous, next) {
      if (next) {
        state = ConnectionStatus.connected;
      } else {
        state = ConnectionStatus.disconnected;
      }
    });

    final connectionChecker = InternetConnectionChecker.createInstance(
      addresses: [
        AddressCheckOption(
          uri: Uri.parse('https://google.com'),
          timeout: const Duration(seconds: 3),
        ),
        AddressCheckOption(
          uri: Uri.parse('https://flutter.dev'),
          timeout: const Duration(seconds: 3),
        ),
      ],
    );

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
        }
      },
    );
    return ConnectionStatus.checking;
  }
}

// TODO: Randomly says disconnected dispite the emulator being connected to the internet
final _connectionProvider =
    NotifierProvider<ConnectionNotifier, ConnectionStatus>(
        ConnectionNotifier.new);

final isOnlineProvider = Provider<bool>((ref) {
  var status = ref.watch(_connectionProvider);
  return status == ConnectionStatus.connected ||
      status == ConnectionStatus.slow;
});

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

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

// ignore: non_constant_identifier_names
final debug_fakeBeingOnlineProvider = StateProvider<bool>((ref) {
  return false;
});

class ConnectionNotifier extends Notifier<ConnectionStatus> {
  // for web only implementation
  int _reconnectionFailCount = 0;
  // Number of times for the reconnection to fail before deciding we are disconnected
  final int _disconnectOnFailCount = 3;
  final Duration _checkInterval = const Duration(seconds: 3);
  @override
  build() {
    ref.listen(debug_fakeBeingOnlineProvider, (previous, next) {
      if (next) {
        state = ConnectionStatus.connected;
      } else {
        state = ConnectionStatus.disconnected;
      }
    });

    // The web implementation for checking the connection
    if (kIsWeb) {
      var running = true;

      ref.onDispose(() => running = false);

      Future.microtask(() async {
        while (running) {
          await Future.delayed(_checkInterval);
          if (!running) break;

          try {
            final response = await Dio().get(
              'https://httpbin.org/get',
              options: Options(
                receiveTimeout: const Duration(seconds: 5),
              ),
            );

            if (!running) break;

            if (response.statusCode == null) {
              _reconnectionFailCount++;
            } else if ((response.statusCode! >= 200 &&
                response.statusCode! < 300)) {
              state = ConnectionStatus.connected;
              _reconnectionFailCount = 0;
            } else {
              _reconnectionFailCount++;
            }
          } catch (_) {
            if (!running) break;
            _reconnectionFailCount++;
          } finally {
            if (_reconnectionFailCount >= _disconnectOnFailCount) {
              state = ConnectionStatus.disconnected;
            }
          }
        }
      });
      return ConnectionStatus.checking;
    }

    // The non-web implementation
    if (!kIsWeb) {
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

      var sub = connectionChecker.onStatusChange.listen(
        (InternetConnectionStatus status) {
          switch (status) {
            case InternetConnectionStatus.disconnected:
              state = ConnectionStatus.disconnected;
              break;
            case InternetConnectionStatus.connected:
              state = ConnectionStatus.connected;
              break;
            case InternetConnectionStatus.slow:
              state = ConnectionStatus.connected;
              break;
          }
        },
      );

      ref.onDispose(() => sub.cancel());
    }
    return ConnectionStatus.checking;
  }
}

final _connectionProvider =
    NotifierProvider<ConnectionNotifier, ConnectionStatus>(
        ConnectionNotifier.new);

final isOnlineProvider = Provider<bool>((ref) {
  var status = ref.watch(_connectionProvider);
  return status == ConnectionStatus.connected;
});

enum ConnectionStatus { checking, connected, disconnected }

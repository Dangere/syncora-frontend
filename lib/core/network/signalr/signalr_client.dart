import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:logger/logger.dart';
import 'package:signalr_netcore/errors.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:syncora_frontend/core/utils/result.dart';

// Exposes method to listen to events from the server
// This handles all the connection and reconnection logic without having to worry about it in other classes
class SignalRClient {
  Stream<HubConnectionState> get onStateChanged => _connection.stateStream;

  final HubConnection _connection;
  late final Logger _logger;
  final Future<Result> Function(CancellationToken) _refreshTokenRequest;

  final int _timeoutAwaitSeconds = 5;

  CancellationToken? _cancelationToken;

  SignalRClient(Logger logger,
      {required String serverUrl,
      required String hub,
      required Future<String> Function() accessTokenFactory,
      required Future<Result> Function(CancellationToken) refreshTokenCallBack})
      : _connection = HubConnectionBuilder()
            .withUrl("$serverUrl/$hub",
                // By default our backend allows connection to persists even if a token expires as long as it was valid at the first handshake
                // This can be overwritten in the backend's signalR options
                options: HttpConnectionOptions(
                  accessTokenFactory: accessTokenFactory,
                ))
            .withAutomaticReconnect(retryDelays: [2000]).build(),
        _logger = logger,
        _refreshTokenRequest = refreshTokenCallBack {
    _logger.i("SignalRClient: constructed");

    // SignalR connection events
    _connection.onreconnected(({connectionId}) {
      _logger.f("SignalRClient: reconnected");
    });
    _connection.onreconnecting(
      ({error}) {
        _logger.f("SignalRClient: reconnecting, error: $error");
      },
    );
    _connection.onclose(
      ({error}) {
        _logger.f("SignalRClient: connection closed");

        if (_cancelationToken == null || _cancelationToken!.isCancelled) return;
        _connectToServer();
      },
    );
  }

  // Tries to establish a connection to the server until it succeeds
  Future<Result> connect() async {
    // return Result.canceled("Canceling connection to hub");
    if (_connection.state == HubConnectionState.Connected) {
      _logger.i("SignalRClient: connection is already connected, skipping");

      return Result.canceled("Connection is not disconnected to connect");
    }
    _cancelationToken = CancellationToken();
    Result result = await _connectToServer();

    if (result.isSuccess) {
      _logger.i("SignalRClient: established");
    }

    return result;
  }

  void dispose() async {
    if (_cancelationToken == null) {
      _logger.f("SignalRClient: tried to dispose without connecting first!");
      return;
    }
    _cancelationToken!.cancel();
    // We have to check that its connected to stop it first, otherwise if we try to stop it while it has a disconnect error, it will bug out and get stuck at "disconnecting" (this happens when we try to call this method when we lose internet connection, it already has a no internet error)
    if (_connection.state == HubConnectionState.Connected) {
      await _connection.stop();
    }
    _logger.f("SignalRClient: disposed!");

    _logger.f(
        "SignalRClient: fully stopped connection to hub, connection state: ${_connection.state}");
    // _cancelationToken = null;
  }

  void on(String method, void Function(List<Object?>?) handler) {
    _connection.on(method, handler);
  }

  void off(String method) {
    _connection.off(method);
  }

  // This will loop until a connection is established or returns an error that isn't an expired token or timeout
  // TODO: Handle server disconnection when connected throws XMLHttpRequest error (web only problem, not native)

  Future<Result> _connectToServer() async {
    while (_connection.state == HubConnectionState.Disconnected &&
        !_cancelationToken!.isCancelled) {
      try {
        // Try to start the connection
        await _connection.start()?.asCancellable(_cancelationToken);

        // If it succeeds, we return
        return Result.success();

        // If it cant start, we process the error and try to reconnect
      } catch (e, stackTrace) {
        if (e is CancelledException) {
          _logger.d("SignalRClient: connection was cancelled, returning");
          return Result.failure(e, stackTrace);
        }

        // If the error is an http error, we see if its an expired token or not
        if (e is HttpError) {
          // If its an expired token, we refresh the tokens and loop again
          if (e.statusCode == 401) {
            _logger.d(
                "SignalRClient: connection failed due to expired tokens, refreshing tokens then trying again");
            await _refreshTokenRequest(_cancelationToken!);
            continue;

            // If its not an expired token, we return
          } else {
            _logger.f("SignalRClient: connection failed with network error $e");
            return Result.failure(e, stackTrace);
          }
        }
        // If the error is a timeout, we wait and try again
        if (e is TimeoutException) {
          _logger.d(
              "SignalRClient: connection timed out, trying again in $_timeoutAwaitSeconds seconds");

          await Future.delayed(Duration(seconds: _timeoutAwaitSeconds));
          continue;
        }

        // If the error is not an http error and not a timeout, we return with fetal error
        _logger.f("SignalRClient: connection failed with fetal error $e");
        return Result.failure(e, stackTrace);
      }
    }

    if (_cancelationToken!.isCancelled) {
      _logger.d("SignalRClient: connection was cancelled, returning");

      return Result.canceled("Canceling connection to hub");
    }

    _logger.d(
        "SignalRClient: tried to connect to server while its ${_connection.state}");
    return Result.canceled(
        "Tried to connect to server while its ${_connection.state}");
  }
}

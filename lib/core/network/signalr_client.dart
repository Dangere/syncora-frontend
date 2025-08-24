import 'package:logger/logger.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';

class SignalRClient {
  final HubConnection _connection;

  HubConnection get connection => _connection;

  SignalRClient(
      {required String serverUrl,
      required String hub,
      required Future<String> Function() accessTokenFactory})
      : _connection = HubConnectionBuilder()
            .withUrl("$serverUrl/$hub",
                // By default our backend allows connection to persists even if a token expires as long as it was valid at the first handshake
                // This can be overwritten in the backend's signalR options
                options: HttpConnectionOptions(
                  accessTokenFactory: accessTokenFactory,
                ))
            .withAutomaticReconnect()
            .build();

  Future<Result<void>> connect() async {
    try {
      // _connection.keepAliveIntervalInMilliseconds = 5000;
      // _connection.serverTimeoutInMilliseconds = 3000;

      await _connection.start();

      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<void>> disconnect() async {
    try {
      await _connection.stop();

      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }
}

import 'package:signalr_netcore/signalr_client.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';

class SignalRClient {
  final HubConnection _connection;

  HubConnection get connection => _connection;

  SignalRClient(
      {required String serverUrl,
      required String hub,
      required String accessToken})
      : _connection = HubConnectionBuilder()
            .withUrl("$serverUrl/$hub",
                options: HttpConnectionOptions(
                  accessTokenFactory: () async => accessToken,
                ))
            .withAutomaticReconnect()
            .build();

  Future<Result<void>> connect() async {
    try {
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

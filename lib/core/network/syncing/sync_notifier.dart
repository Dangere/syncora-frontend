import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:sqflite/sqflite.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/core/network/signalr_client.dart';
import 'package:syncora_frontend/core/network/syncing/model/sync_payload.dart';
import 'package:syncora_frontend/core/network/syncing/sync_repository.dart';
import 'package:syncora_frontend/core/network/syncing/sync_service.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';
import 'package:syncora_frontend/features/tasks/viewmodel/tasks_providers.dart';
import 'package:syncora_frontend/features/users/viewmodel/users_providers.dart';

class SyncBackendNotifier extends AsyncNotifier<int>
    with WidgetsBindingObserver {
  SignalRClient? _syncSignalRClient;

  final int _retryingServerConnectDurationInSeconds = 5;
  final int _retryingServerConnectTries = 200;
  bool _isDisposed = false;

  bool disableSyncing = false;

  void toggleSyncing() {
    disableSyncing = !disableSyncing;
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   switch (state) {
  //     case AppLifecycleState.resumed:
  //       ensureConnected();
  //       break;

  //     default:
  //   }
  //   super.didChangeAppLifecycleState(state);
  // }

  Future<void> syncData() async {
    if (disableSyncing) return;

    // TODO: Instead of waiting for it to finish loading, we should schedule it to run in the future for new data
    if (state.isLoading) return;

    if (ref.read(isGuestProvider)) {
      ref.read(appErrorProvider.notifier).state =
          AppError(message: "Can't sync and backup data when in guest mode");
      state = AsyncValue.error(
          "Can't sync and backup data when in guest mode", StackTrace.current);

      return;
    }

    if (ref.read(connectionProvider) == ConnectionStatus.disconnected) {
      ref.read(appErrorProvider.notifier).state =
          AppError(message: "Can't sync when offline");
      state = AsyncValue.error("Can't sync when offline", StackTrace.current);

      return;
    }

    state = const AsyncValue.loading();
    Result<SyncPayload> result =
        await ref.read(syncServiceProvider).syncFromServer();

    if (!result.isSuccess) {
      ref.read(appErrorProvider.notifier).state = result.error;
      state = AsyncValue.error(result.error!, StackTrace.current);
      return;
    }

    // ref.read(loggerProvider).i("Formatted data: ${result.data?.toString()}");

    // Updating the groups notifier with the new data if it exists and there are groups
    if (ref.exists(groupsNotifierProvider)) {
      ref.read(groupsNotifierProvider.notifier).reloadGroups();
    }
    HashSet<int> changedGroups = result.data!.groupIds();

    // Updating the groups notifier with the new data
    changedGroups.forEach((element) {
      if (ref.exists(groupProvider(element))) {
        ref.invalidate(groupProvider(element));
      }
    });

    // Make sure to update any part of the UI that might be listening to groups/users/tasks

    state = const AsyncValue.data(0);
  }

  Future<Result> initializeConnection() async {
    Result result = await _initializeConnection();

    if (!result.isSuccess && !_isDisposed) {
      ref.read(appErrorProvider.notifier).state = result.error!;
      state = AsyncValue.error(result.error!.message,
          result.error!.stackTrace ?? StackTrace.current);

      // if (!_isRetryingInitialization) _retryHubInitialization();
    }
    return result;
  }

  Future<Result> _initializeConnection() async {
    String? accessToken = ref.read(sessionStorageProvider).accessToken;

    if (accessToken == null) {
      return Result.failure(
          AppError(message: "No access token", stackTrace: StackTrace.current));
    }

    _syncSignalRClient = SignalRClient(
        serverUrl: Constants.BASE_HUB_URL,
        hub: "sync",
        accessTokenFactory: () async =>
            Future.value(ref.read(sessionStorageProvider).accessToken!));

    _syncSignalRClient!.connection.on("ReceiveSync", _receiveSyncData);
    _syncSignalRClient!.connection.onclose(_onClosedConnection);
    _syncSignalRClient!.connection.onreconnecting(_onHubReconnecting);
    _syncSignalRClient!.connection.onreconnected(_onHubReconnect);

    return await _startHubConnection();
  }

  // This here tries to initial only the first connection to the backend's hub
  // Next reconnections are happening elsewhere
  Future<Result> _startHubConnection() async {
    state = const AsyncValue.loading();

    if (_syncSignalRClient == null) {
      return Result.failure(AppError(
          message: "SignalR connection isn't initialized",
          stackTrace: StackTrace.current));
    }

    ref.read(loggerProvider).i("Starting hub connection");
    late Result result;

    // We try to connect to the hub a specified number of times (_retryingServerConnectTries)
    for (var i = 0; i < _retryingServerConnectTries; i++) {
      if (_isDisposed) {
        return Result.failure(AppError(
            message: "Sync notifier is disposed",
            stackTrace: StackTrace.current));
      }

      // Try to connect to the hub
      result = await _syncSignalRClient!.connect();
      if (!result.isSuccess &&
          _syncSignalRClient!.connection.state ==
              HubConnectionState.Disconnected) {
        // If we getting 401 as a return error, it means our tokens are expired, we then try to refresh tokens then ,
        if (result.error!.is401UnAuthorizedError()) {
          await ref.read(authNotifierProvider.notifier).refreshTokens();
        }

        // If its not 401, then we keep retrying a specified number of times (_retryingServerConnectTries)
        ref.read(loggerProvider).e(result.error!.message);
        // We wait a duration
        await Future.delayed(
            Duration(seconds: _retryingServerConnectDurationInSeconds));
      } else {
        // If we get a successful result, we set the state to data so UI updates and we break the loop which returns the final result
        state = const AsyncValue.data(0);
        break;
      }
    }
    return result;
  }

  Future<Result> _stopHubConnection() async {
    if (_syncSignalRClient == null) {
      return Result.success(null);
    }
    state = const AsyncValue.loading();
    Result result = await _syncSignalRClient!.disconnect();

    if (!result.isSuccess) {
      return result;
    }

    state = const AsyncValue.data(0);
    return Result.success(null);
  }

  void _receiveSyncData(List<Object?>? parameters) {
    syncData();
  }

  void _onClosedConnection({Exception? error}) {
    ref.read(loggerProvider).d("Connection with the server has been closed");
    // Make it so it tries to reconnect to the hub after a specified duration
    if (error != null) {
      ref.read(appErrorProvider.notifier).state = AppError(
          message: error.toString(),
          errorObject: error,
          stackTrace: StackTrace.current);
      ref
          .read(loggerProvider)
          .d("Connection with the server has been closed, error: $error");
    }

    _startHubConnection();
  }

  void _onHubReconnecting({Exception? error}) {
    state = const AsyncValue.loading();
    ref.read(loggerProvider).d("Reconnecting to hub");
  }

  void _onHubReconnect({String? connectionId}) {
    state = const AsyncValue.data(0);
    ref.read(loggerProvider).d("Reconnected to hub");
  }

  void dispose() {
    _stopHubConnection();
    _syncSignalRClient = null;
    WidgetsBinding.instance.removeObserver(this);
    Logger().d("Sync notifier disposed");
    _isDisposed = true;
  }

  // TODO: Fix the loading state of the notifier
  @override
  FutureOr<int> build() async {
    // ConnectionStatus connectionStatus =
    //     ref.watch(connectionProvider.select((value) {
    //   // Making sure we are only listening to changes to ConnectionStatus.connected/ConnectionStatus.disconnected/ConnectionStatus.checking only
    //   if (value != ConnectionStatus.slow) return value;
    //   return ConnectionStatus.connected;
    // }));
    _isDisposed = false;
    ConnectionStatus connectionStatus = ref.watch(connectionProvider);
    var authState = ref.watch(authNotifierProvider);

    switch (connectionStatus) {
      case ConnectionStatus.disconnected:
        throw AppError(
            message: "Not connected to the internet",
            stackTrace: StackTrace.current);

      case ConnectionStatus.checking:
        return Completer<int>().future;
      default:
    }

    authState.when(
        data: (data) {
          if (data.isUnauthenticated) {
            throw AppError(
                message: "User is not logged in",
                stackTrace: StackTrace.current);
          }

          if (data.isGuest) {
            throw AppError(
                message: "Current user is a guest",
                stackTrace: StackTrace.current);
          }
        },
        error: (error, stackTrace) {
          throw error;
        },
        loading: () => Completer<int>().future);

    if (authState.isLoading) {
      return Completer<int>().future;
    }

    WidgetsBinding.instance.addObserver(this);

    Result result = await initializeConnection();

    if (!result.isSuccess) {
      throw result.error!;
    }

    await syncData();
    ref.onDispose(dispose);

    return 0;
  }
}

final syncBackendNotifierProvider =
    AsyncNotifierProvider<SyncBackendNotifier, int>(SyncBackendNotifier.new);

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
      syncRepository: ref.watch(syncRepositoryProvider),
      groupsService: ref.watch(groupsServiceProvider),
      usersService: ref.watch(usersServiceProvider),
      tasksService: ref.watch(tasksServiceProvider));
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(
      dio: ref.watch(dioProvider), databaseManager: ref.watch(localDbProvider));
});

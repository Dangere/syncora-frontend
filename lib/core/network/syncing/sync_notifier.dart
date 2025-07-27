import 'dart:async';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/core/network/signalr_client.dart';
import 'package:syncora_frontend/core/network/syncing/sync_repository.dart';
import 'package:syncora_frontend/core/network/syncing/sync_service.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';
import 'package:syncora_frontend/features/users/viewmodel/users_providers.dart';

class SyncBackendNotifier extends AsyncNotifier<int>
    with WidgetsBindingObserver {
  SignalRClient? _syncSignalRClient;
  late Logger _logger;
  bool _isRetryingConnection = false;
  bool _isRetryingInitialization = false;

  final int _retryingDurationInSeconds = 5;

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

  // Future<void> syncData() async {
  //   if (state.isLoading) return;

  //   if (ref.read(isGuestProvider)) {
  //     ref.read(appErrorProvider.notifier).state =
  //         AppError("Can't sync and backup data when in guest mode");
  //     state = AsyncValue.error(
  //         "Can't sync and backup data when in guest mode", StackTrace.current);

  //     return;
  //   }

  //   if (ref.read(connectionProvider) == ConnectionStatus.disconnected) {
  //     ref.read(appErrorProvider.notifier).state =
  //         AppError("Can't sync when offline");
  //     state = AsyncValue.error("Can't sync when offline", StackTrace.current);

  //     return;
  //   }

  //   // ref.read(loggerProvider).d(ref.read(authNotifierProvider));

  //   state = const AsyncValue.loading();
  //   Result<void> result = await ref.read(syncServiceProvider).syncFromServer();

  //   if (!result.isSuccess) {
  //     ref.read(appErrorProvider.notifier).state = result.error;
  //     state = AsyncValue.error(result.error!, StackTrace.current);
  //     return;
  //   }

  //   // Updating the groups notifier with the new data if it exists and there are groups
  //   if (ref.exists(groupsNotifierProvider)) {
  //     ref.read(groupsNotifierProvider.notifier).reloadGroups();
  //   }
  //   // Make sure to update any part of the UI that might be listening to groups/users/tasks

  //   state = const AsyncValue.data(null);
  // }

  Future<Result> initializeConnection() async {
    Result result = await _initializeConnection();

    if (!result.isSuccess) {
      ref.read(appErrorProvider.notifier).state = result.error!;
      state = AsyncValue.error(result.error!.message,
          result.error!.parsedStackTrace ?? StackTrace.current);

      // if (!_isRetryingInitialization) _retryHubInitialization();
    }
    return result;
  }

  Future<Result> _initializeConnection() async {
    String? accessToken = ref.read(sessionStorageProvider).token;

    if (accessToken == null) {
      return Result.failure(AppError("No access token", StackTrace.current));
    }

    _syncSignalRClient = SignalRClient(
        serverUrl: Constants.BASE_HUB_URL,
        hub: "sync",
        accessToken: accessToken);

    _syncSignalRClient!.connection.on("ReceiveSync", _receiveSyncData);
    _syncSignalRClient!.connection.onclose(_onClosedConnection);
    _syncSignalRClient!.connection.onreconnecting(_onHubReconnecting);
    _syncSignalRClient!.connection.onreconnected(_onHubReconnect);

    return await _startHubConnection();
  }

  Future<Result> _startHubConnection() async {
    state = const AsyncValue.loading();

    if (_syncSignalRClient == null) {
      return Result.failure(
          AppError("SignalR connection isn't initialized", StackTrace.current));
    }

    ref.read(loggerProvider).i("Starting hub connection");
    Result result = await _syncSignalRClient!.connect();

    if (!result.isSuccess) {
      if (!_isRetryingConnection) _retryHubConnection();
      return result;
    }

    state = const AsyncValue.data(0);
    return Result.success(null);
  }

  void _retryHubConnection() async {
    _isRetryingConnection = true;
    while (_syncSignalRClient?.connection.state ==
        HubConnectionState.Disconnected) {
      Result result = await _startHubConnection();
      if (!result.isSuccess) {
        state =
            AsyncValue.error("Unable to connect to hub", StackTrace.current);

        _logger.e(result.error!.message);
      }
      await Future.delayed(Duration(seconds: _retryingDurationInSeconds));
    }
    _isRetryingConnection = false;
  }

  // void _retryHubInitialization() async {
  //   _isRetryingInitialization = true;
  //   while (_syncSignalRClient == null) {
  //     Result result = await _initializeConnection();
  //     if (!result.isSuccess) {
  //       state =
  //           AsyncValue.error("Unable to initialize hub", StackTrace.current);
  //       _logger.w(result.error!.message);
  //     }
  //     await Future.delayed(Duration(seconds: _retryingDurationInSeconds));
  //   }
  //   _isRetryingInitialization = false;
  // }

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
    ref.read(loggerProvider).d("Server invoked the method");
  }

  void _onClosedConnection({Exception? error}) {
    ref.read(loggerProvider).d("Connection with the server has been closed");

    if (error != null) {
      ref.read(appErrorProvider.notifier).state = AppError(error.toString());
      ref
          .read(loggerProvider)
          .d("Connection with the server has been closed, error: $error");
    }
  }

  void _onHubReconnecting({Exception? error}) {
    state = const AsyncValue.loading();
    _logger.d("Reconnecting to hub");
  }

  void _onHubReconnect({String? connectionId}) {
    state = const AsyncValue.data(0);
    _logger.d("Reconnected to hub");
  }

  void dispose() {
    _stopHubConnection();
    _syncSignalRClient = null;
    WidgetsBinding.instance.removeObserver(this);
    _logger.d("Sync notifier disposed");
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
    ref.onDispose(dispose);

    // ConnectionStatus connectionStatus = ref.watch(connectionProvider);
    // var authState = ref.watch(authNotifierProvider);

    // switch (connectionStatus) {
    //   case ConnectionStatus.disconnected:
    //     throw AppError("Not connected to the internet", StackTrace.current);

    //   case ConnectionStatus.checking:
    //     return Completer<int>().future;
    //   default:
    // }

    // authState.when(
    //     data: (data) {
    //       if (data.isUnauthenticated) {
    //         throw AppError("User is not logged in", StackTrace.current);
    //       }

    //       if (data.isGuest) {
    //         throw AppError("Current user is a guest", StackTrace.current);
    //       }
    //     },
    //     error: (error, stackTrace) {
    //       throw error;
    //     },
    //     loading: () => Completer<int>().future);

    // if (authState.isLoading) {
    //   return Completer<int>().future;
    // }

    WidgetsBinding.instance.addObserver(this);
    _logger = ref.watch(loggerProvider);

    Result result = await initializeConnection();

    if (!result.isSuccess) {
      throw result.error!;
    }

    return 0;
  }
}

final syncBackendNotifierProvider =
    AsyncNotifierProvider<SyncBackendNotifier, int>(SyncBackendNotifier.new);

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
      syncRepository: ref.watch(syncRepositoryProvider),
      groupsService: ref.watch(groupsServiceProvider),
      usersService: ref.watch(usersServiceProvider));
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(
      dio: ref.watch(dioProvider), databaseManager: ref.watch(localDbProvider));
});

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
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

class SyncBackendNotifier extends AsyncNotifier<void>
    with WidgetsBindingObserver {
  SignalRClient? _syncSignalRClient;
  late Logger _logger;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        ensureConnected();
        break;

      default:
    }
    super.didChangeAppLifecycleState(state);
  }

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

  Future<void> ensureConnected() async {
    if (ref.read(isGuestProvider) ||
        ref.read(connectionProvider) == ConnectionStatus.disconnected) {
      ref.read(appErrorProvider.notifier).state = AppError(
          "Can't initialize sync connection when in guest mode or offline");
      state = AsyncValue.error(
          "Can't initialize sync connection when in guest mode or offline",
          StackTrace.current);

      return;
    }
    state = const AsyncValue.loading();

    if (_syncSignalRClient != null) {
      return await _startHubConnection();
    }

    String? accessToken = ref.read(sessionStorageProvider).token;

    if (accessToken == null) {
      ref.read(appErrorProvider.notifier).state = AppError("No access token");
      state = AsyncValue.error("No access token", StackTrace.current);
      return;
    }

    _syncSignalRClient = SignalRClient(
        serverUrl: Constants.BASE_HUB_URL,
        hub: "sync",
        accessToken: accessToken);

    _syncSignalRClient!.connection.on("ReceiveSync", _receiveSyncData);
    _syncSignalRClient!.connection.onclose(_onClosedConnection);

    return await _startHubConnection();
  }

  Future<void> _startHubConnection() async {
    state = const AsyncValue.loading();

    ref.read(loggerProvider).i("Starting hub connection");
    Result result = await _syncSignalRClient!.connect();

    if (!result.isSuccess) {
      ref.read(appErrorProvider.notifier).state = result.error!;
      state = AsyncValue.error(result.error!, StackTrace.current);

      return;
    }

    // state = const AsyncValue.data(null);
  }

  Future<void> _stopHubConnection() async {
    if (_syncSignalRClient == null) {
      return;
    }
    Result result = await _syncSignalRClient!.disconnect();

    if (!result.isSuccess) {
      ref.read(appErrorProvider.notifier).state = result.error!;
      state = AsyncValue.error(result.error!, StackTrace.current);
    }
  }

  void _receiveSyncData(List<Object?>? parameters) {
    ref.read(loggerProvider).d("Server invoked the method");
  }

  void _onClosedConnection({Exception? error}) {
    ref
        .read(loggerProvider)
        .d("Connection with the server has been closed. $error");

    // state = AsyncValue.error(
    //     "Connection with the server has been closed", StackTrace.current);

    // ref.read(appErrorProvider.notifier).state =
    //     AppError("Connection with the server has been closed");
  }

  void dispose() {
    _stopHubConnection();
    _syncSignalRClient = null;
    WidgetsBinding.instance.removeObserver(this);
    _logger.d("Sync notifier disposed");
  }

  // TODO: Fix the loading state of the notifier
  @override
  FutureOr<void> build() async {
    WidgetsBinding.instance.addObserver(this);
    _logger = ref.watch(loggerProvider);
    ref.read(loggerProvider).d("Initializing sync notifier");

    ref.onDispose(dispose);
  }
}

final syncBackendNotifierProvider =
    AsyncNotifierProvider<SyncBackendNotifier, void>(SyncBackendNotifier.new);

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

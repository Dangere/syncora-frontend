import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/core/network/signalr/signalr_client.dart';
import 'package:syncora_frontend/core/network/syncing/model/sync_payload.dart';
import 'package:syncora_frontend/core/network/syncing/sync_repository.dart';
import 'package:syncora_frontend/core/network/syncing/sync_service.dart';
import 'package:syncora_frontend/core/network/syncing/sync_state.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';
import 'package:syncora_frontend/features/tasks/viewmodel/tasks_providers.dart';
import 'package:syncora_frontend/features/users/viewmodel/users_providers.dart';

// TODO: this needs needs serious refactoring with heavy focus on separation of concerns
class SyncBackendNotifier extends AsyncNotifier<SyncState>
    with WidgetsBindingObserver {
  // When this is enabled, on each time the event payload is received from signalR
  // A fetch call to the state payload will be called to compare both event vs state data, which should be almost the same
  final bool debugEventPayloadCheck = true;

  @override
  FutureOr<SyncState> build() async {
    WidgetsBinding.instance.addObserver(this);

    ref.read(loggerProvider).d("Sync Notifier: building sync backend notifier");

    ref.read(signalRClientProvider).onStateChanged.listen((event) {
      switch (event) {
        case HubConnectionState.Connected:
          ref
              .read(loggerProvider)
              .d("Sync Notifier: refreshing data on server connect");

          state = const AsyncValue.data(SyncIdle());
          _refreshData();
          break;
        case HubConnectionState.Disconnected:
          ref
              .read(loggerProvider)
              .d("Sync Notifier: we lost connection to server");

          state = const AsyncValue.data(SyncDisconnected());
          break;
        case HubConnectionState.Connecting:
          ref
              .read(loggerProvider)
              .d("Sync Notifier: we are connecting to server");

          state = const AsyncValue.loading();
          break;

        case HubConnectionState.Reconnecting:
          ref
              .read(loggerProvider)
              .d("Sync Notifier: we are reconnecting to server");

          state = const AsyncValue.loading();
          break;

        case HubConnectionState.Disconnecting:
          ref
              .read(loggerProvider)
              .d("Sync Notifier: we are disconnecting to server");

          state = const AsyncValue.loading();
      }
    });

    ref
        .read(signalRClientProvider)
        .on("ReceiveSync", (p0) => _receiveData(p0?.first));

    ref
        .read(signalRClientProvider)
        .on("ReceiveVerification", (p0) => _receiveVerification(p0));

    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));

    return const SyncIdle();
  }

  void _receiveData(Object? parameter) async {
    if (parameter == null || parameter is! Map<String, dynamic>) return;
    if (ref.read(connectionProvider) == ConnectionStatus.disconnected) return;
    if (ref.read(isAuthenticatedProvider) == false) return;

    SyncPayload eventPayload = SyncPayload.fromJson(parameter);

    if (debugEventPayloadCheck) {
      ref
          .read(loggerProvider)
          .d("Sync Notifier: event payload, ${eventPayload.toString()}");
      SyncPayload statePayload =
          (await ref.read(syncServiceProvider).fetchPayload()).data!;

      ref
          .read(loggerProvider)
          .d("Sync Notifier: state payload, ${statePayload.toString()}");
    }

    state = const AsyncValue.loading();

    Result<void> result =
        await ref.read(syncServiceProvider).processPayload(eventPayload);
    if (!result.isSuccess) {
      state = AsyncValue.error(result.error!.errorObject,
          result.error!.stackTrace ?? StackTrace.current);
      return;
    }

    state = AsyncValue.data(SyncInProgress(eventPayload));
  }

  Future<void> _refreshData() async {
    if (state.isLoading) return;

    if (ref.read(connectionProvider) == ConnectionStatus.disconnected) return;
    if (ref.read(isAuthenticatedProvider) == false) return;

    state = const AsyncValue.loading();
    Result<SyncPayload> result =
        await ref.read(syncServiceProvider).refreshFromServer();

    if (!result.isSuccess) {
      state = AsyncValue.error(result.error!.errorObject,
          result.error!.stackTrace ?? StackTrace.current);
      return;
    }

    state = AsyncValue.data(SyncInProgress(result.data!));
  }

  void _receiveVerification(List<Object?>? parameters) {
    bool isVerified = parameters?[0] as bool;

    if (!isVerified) return;

    ref
        .read(authNotifierProvider.notifier)
        .updateVerificationStatus(isVerified);
  }

  // Handling when the app is resumed, recalling the sync just to make sure we are up to date
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(loggerProvider).d("Sync Notifier: syncing on resume");
      _refreshData();
    }
  }
}

final syncBackendNotifierProvider =
    AsyncNotifierProvider<SyncBackendNotifier, SyncState>(
        SyncBackendNotifier.new);

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
      ref.watch(syncRepositoryProvider),
      ref.watch(localGroupsRepositoryProvider),
      ref.watch(localTasksRepositoryProvider),
      ref.watch(localUsersRepositoryProvider));
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(
      dio: ref.watch(dioProvider), databaseManager: ref.watch(localDbProvider));
});

final debug_disposeSignalRProvider = StateProvider<bool>((ref) {
  return false;
});

final signalRClientProvider = Provider<SignalRClient>((ref) {
  SignalRClient client = SignalRClient(
    ref.read(loggerProvider),
    hub: "sync",
    serverUrl: Constants.BASE_HUB_URL,
    accessTokenFactory: () async =>
        Future.value(ref.read(sessionStorageProvider).tokens?.accessToken),
    refreshTokenCallBack: ref.read(authNotifierProvider.notifier).refreshTokens,
  );

  ref.onDispose(() {
    ref.read(loggerProvider).d("Auto disposing connection to hub");
    client.dispose();
  });

  ref.listen(debug_disposeSignalRProvider, (previous, next) {
    if (next) {
      ref
          .read(loggerProvider)
          .d("signalRClientProvider: debug mode enabled, disposing connection");
      client.dispose();
    }
  });

  // Listen for authentication changes
  ref.listen(isAuthenticatedProvider, (previous, next) {
    if (next) {
      if (ref.read(connectionProvider) == ConnectionStatus.disconnected) return;
      ref
          .read(loggerProvider)
          .d("signalRClientProvider: User is authenticated, connecting to hub");
      client.connect();
    } else {
      ref.read(loggerProvider).d(
          "signalRClientProvider: User is unauthenticated, disposing connection");

      client.dispose();
    }
  });

  // Listen for connection changes
  ref.listen(connectionProvider, (previous, next) {
    if (!(next == ConnectionStatus.disconnected)) {
      if (!ref.read(isAuthenticatedProvider)) return;
      ref
          .read(loggerProvider)
          .d("signalRClientProvider: internet reconnected, connecting to hub");
      client.connect();
    } else {
      ref.read(loggerProvider).d(
          "signalRClientProvider: internet disconnected, disposing connection");
      client.dispose();
    }
  });
  return client;
});

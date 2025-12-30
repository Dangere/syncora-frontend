import 'dart:async';
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
  @override
  FutureOr<SyncState> build() async {
    WidgetsBinding.instance.addObserver(this);

    ref.read(loggerProvider).d("Sync Notifier: building sync backend notifier");

    ref.read(signalRClientProvider).onStateChanged.listen((event) {
      switch (event) {
        case HubConnectionState.Connected:
          state = const AsyncValue.data(SyncIdle());
          _syncData();
          break;
        case HubConnectionState.Disconnected:
          state = const AsyncValue.data(SyncDisconnected());
          break;
        case HubConnectionState.Connecting:
          state = const AsyncValue.loading();
          break;

        case HubConnectionState.Reconnecting:
          state = const AsyncValue.loading();
          break;

        case HubConnectionState.Disconnecting:
          state = const AsyncValue.loading();
      }
    });

    // (await ref.read(signalRClientProvider).connect()).onError((error) {
    //   ref.read(appErrorProvider.notifier).state = error;
    //   throw error.errorObject;
    // });

    ref.read(signalRClientProvider).on("ReceiveSync", (p0) => _syncData());
    ref
        .read(signalRClientProvider)
        .on("ReceiveVerification", (p0) => _receiveVerification(p0));

    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));

    return const SyncIdle();
  }

  Future<void> _syncData() async {
    // TODO: Instead of waiting for it to finish loading, we should schedule it to run in the future for new data
    if (state.isLoading) return;

    state = const AsyncValue.loading();
    Result<SyncPayload> result =
        await ref.read(syncServiceProvider).syncFromServer();

    if (!result.isSuccess) {
      state = AsyncValue.error(result.error!, StackTrace.current);
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
      _syncData();
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

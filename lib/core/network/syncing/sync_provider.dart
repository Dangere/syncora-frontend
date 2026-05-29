import 'dart:async';
import 'dart:collection';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/core/error_management/error_provider.dart';
import 'package:syncora_frontend/core/localization/generated/l10n/app_localizations.dart';
import 'package:syncora_frontend/core/network/signalr/signalr_client.dart';
import 'package:syncora_frontend/core/network/syncing/model/sync_payload.dart';
import 'package:syncora_frontend/core/network/syncing/sync_repository.dart';
import 'package:syncora_frontend/core/network/syncing/sync_service.dart';
import 'package:syncora_frontend/core/network/syncing/sync_state.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/groups/groups_provider.dart';
import 'package:syncora_frontend/features/tasks/tasks_provider.dart';
import 'package:syncora_frontend/features/users/providers/users_provider.dart';
import 'package:syncora_frontend/router.dart';

// TODO(DONE): this needs needs serious refactoring with heavy focus on separation of concerns
class SyncBackendNotifier extends AsyncNotifier<SyncState>
    with WidgetsBindingObserver {
  // When this is enabled, on each time the event payload is received from signalR
  // A fetch call to the state payload will be called to compare both event vs state data, which should be almost the same
  // final bool _debugEventPayloadCheck = false;
  bool _isProcessing = false;
  final Queue<SyncPayload> _payloadQueue = Queue<SyncPayload>();

  @override
  FutureOr<SyncState> build() async {
    WidgetsBinding.instance.addObserver(this);

    ref.read(loggerProvider).d("Sync Notifier: building sync backend notifier");

    ref.read(signalRClientProvider).onStateChanged.listen((event) {
      BuildContext? context = navigatorKey.currentContext;

      switch (event) {
        case HubConnectionState.Connected:
          if (context != null && context.mounted) {
            if (state is SyncDisconnected) {
              SnackBarAlerts.showSuccessSnackBar(
                  AppLocalizations.of(context).notification_Backend_Connected,
                  context);
            }
          }

          ref
              .read(loggerProvider)
              .d("Sync Notifier: refreshing data on server connect");

          state = const AsyncValue.data(SyncIdle());
          refreshData();
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

    return const SyncDisconnected();
  }

  // TODO: We could potentially ignore events coming from this device and only process events from other devices
  void _receiveData(Object? parameter) async {
    // return;
    ref.read(loggerProvider).d("Sync Notifier: received data from server");
    if (parameter == null || parameter is! Map<String, dynamic>) return;
    if (!ref.read(isOnlineProvider)) return;
    if (ref.read(isAuthenticatedProvider) == false) return;

    SyncPayload result = SyncPayload.fromJson(parameter);

    _payloadQueue.add(result);
    _processQueue();
  }

  Future<void> refreshData() async {
    if (!ref.read(isOnlineProvider)) return;
    if (ref.read(isAuthenticatedProvider) == false) return;

    Result<SyncPayload> result =
        await ref.read(syncServiceProvider).fetchPayload();

    if (!result.isSuccess) {
      ref.read(appErrorProvider.notifier).setError(result.error!);
      return;
    }
    _payloadQueue.add(result.data!);
    _processQueue();
  }

  Future<void> _processQueue() async {
    // return;
    // TODO: A queue merge could be done here
    if (_isProcessing) return Future.value();
    _isProcessing = true;

    while (_payloadQueue.isNotEmpty) {
      SyncPayload payload = _payloadQueue.removeFirst();

      ref
          .read(loggerProvider)
          .d("Sync Notifier: processing payload: ${payload.toString()}");

      Result<void> result =
          await ref.read(syncServiceProvider).processPayload(payload);

      if (!result.isSuccess) {
        ref.read(appErrorProvider.notifier).setError(result.error!);
        return;
      }

      state = AsyncValue.data(SyncAvailable(payload));
    }
    _isProcessing = false;

    return Future.value();
  }

  void _receiveVerification(List<Object?>? parameters) {
    bool isVerified = parameters?[0] as bool;

    if (!isVerified) return;

    ref
        .read(loggerProvider)
        .d("Sync Notifier: user is verified, updating verification status");

    ref.read(authProvider.notifier).updateVerificationStatus();
  }

  // Handling when the app is resumed, recalling the sync just to make sure we are up to date
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // if (state == AppLifecycleState.resumed) {
    //   ref.read(loggerProvider).d("Sync Notifier: syncing on resume");
    //   _refreshData();
    // }
  }
}

final syncBackendProvider =
    AsyncNotifierProvider<SyncBackendNotifier, SyncState>(
        SyncBackendNotifier.new);

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
      ref.watch(syncRepositoryProvider),
      ref.watch(localGroupsRepositoryProvider),
      ref.watch(localTasksRepositoryProvider),
      ref.watch(localUsersRepositoryProvider),
      authState: () => ref.read(authStateProvider));
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(
      dio: ref.watch(dioProvider), databaseManager: ref.watch(localDbProvider));
});

final debug_disposeSignalRProvider = StateProvider<bool>((ref) {
  return false;
});

final signalRClientProvider = Provider<SignalRClient>((ref) {
  SignalRClient client = SignalRClient(ref.read(loggerProvider),
      hub: "sync",
      serverUrl: Constants.BASE_HUB_URL,
      accessTokenFactory: () async =>
          Future.value(ref.read(sessionStorageProvider).tokens?.accessToken),
      refreshTokenCallBack: ref.read(authProvider.notifier).refreshTokens,
      deviceId: ref.read(diagnosticsServiceProvider).deviceId);

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
      if (!ref.read(isOnlineProvider)) return;
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
  ref.listen(isOnlineProvider, (previous, next) {
    if (next) {
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

final connectedToBackendProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(syncBackendProvider).valueOrNull is! SyncDisconnected;
});

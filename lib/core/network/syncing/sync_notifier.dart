import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/core/constants/constants.dart';
import 'package:syncora_frontend/core/network/signalr_client.dart';
import 'package:syncora_frontend/core/network/syncing/model/sync_payload.dart';
import 'package:syncora_frontend/core/network/syncing/sync_repository.dart';
import 'package:syncora_frontend/core/network/syncing/sync_service.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/services/groups_service.dart';
import 'package:syncora_frontend/features/groups/viewmodel/groups_viewmodel.dart';
import 'package:syncora_frontend/features/users/services/users_service.dart';
import 'package:syncora_frontend/features/users/viewmodel/users_providers.dart';

class SyncBackendNotifier extends AsyncNotifier<void> {
  late SignalRClient? _syncSignalRClient;
  late final SyncService _syncService;
  late final GroupsService _groupsService;
  late final UsersService _usersService;

  // Future<void> sync() async {
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
  //   Result<SyncPayload> result = await _syncService.syncFromServer();

  //   if (!result.isSuccess) {
  //     ref.read(appErrorProvider.notifier).state = result.error;
  //     state = AsyncValue.error(result.error!, StackTrace.current);
  //     return;
  //   }

  //   Result<void> upsertUsersResult =
  //       await _usersService.upsertUsers(result.data!.users);

  //   if (!upsertUsersResult.isSuccess) {
  //     ref.read(appErrorProvider.notifier).state = upsertUsersResult.error!;
  //     state = AsyncValue.error(upsertUsersResult.error!, StackTrace.current);
  //     return;
  //   }

  //   Result<void> upsertGroupsResult =
  //       await _groupsService.upsertGroups(result.data!.groups);

  //   if (!upsertGroupsResult.isSuccess) {
  //     ref.read(appErrorProvider.notifier).state = upsertGroupsResult.error!;
  //     state = AsyncValue.error(upsertGroupsResult.error!, StackTrace.current);
  //     return;
  //   }
  //   // TODO: upsert tasks

  //   // Updating the groups notifier with the new data if it exists and there are groups
  //   if (ref.exists(groupsNotifierProvider) && result.data!.groups.isNotEmpty) {
  //     ref.read(groupsNotifierProvider.notifier).reloadGroups();
  //   }
  //   // Make sure to update any part of the UI that might be listening to groups/users/tasks

  //   state = const AsyncValue.data(null);
  // }

  Future<void> initiate() async {
    if (ref.read(isGuestProvider) ||
        ref.read(connectionProvider) == ConnectionStatus.disconnected) {
      ref.read(appErrorProvider.notifier).state = AppError(
          "Can't initialize sync connection when in guest mode or offline");
      state = AsyncValue.error(
          "Can't initialize sync connection when in guest mode or offline",
          StackTrace.current);

      return;
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
  }

  Future<void> startHubConnection() async {
    if (_syncSignalRClient == null) {
      ref.read(appErrorProvider.notifier).state =
          AppError("signalR client is not initialized");
      state = AsyncValue.error(
          "signalR client is not initialized", StackTrace.current);
      return;
    }
    ref.read(loggerProvider).i("Starting hub connection");
    Result result = await _syncSignalRClient!.connect();

    if (!result.isSuccess) {
      ref.read(appErrorProvider.notifier).state = result.error!;
      state = AsyncValue.error(result.error!, StackTrace.current);
    }
  }

  Future<void> stopHubConnection() async {
    if (_syncSignalRClient == null) {
      ref.read(appErrorProvider.notifier).state =
          AppError("signalR client is not initialized");
      state = AsyncValue.error(
          "signalR client is not initialized", StackTrace.current);
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

  @override
  FutureOr<void> build() {
    _syncService = ref.read(syncServiceProvider);
    // Careful, group service is not immutable
    _groupsService = ref.read(groupsServiceProvider);
    _usersService = ref.read(usersServiceProvider);
  }
}

final syncBackendProvider =
    AsyncNotifierProvider<SyncBackendNotifier, void>(SyncBackendNotifier.new);

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(syncRepository: ref.read(syncRepositoryProvider));
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(
      dio: ref.read(dioProvider), databaseManager: ref.read(localDbProvider));
});

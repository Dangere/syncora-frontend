import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/image/image_provider.dart';
import 'package:syncora_frontend/core/network/syncing/sync_state.dart';
import 'package:syncora_frontend/core/network/syncing/sync_viewmodel.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/users/repositories/local_users_repository.dart';
import 'package:syncora_frontend/features/users/repositories/remote_users_repository.dart';
import 'package:syncora_frontend/features/users/services/users_service.dart';

final userProfileImage =
    FutureProvider.family.autoDispose<Uint8List?, int>((ref, userId) async {
  Result<Uint8List?> result =
      await ref.read(usersServiceProvider).getUserProfilePicture(userId);

  if (!result.isSuccess) {
    throw result.error!.errorObject;
  }

  return result.data;
});

final usersOrchestratorProvider = Provider<int>((ref) {
  // ref.listen(
  //   authNotifierProvider,
  //   (previous, next) {
  //     if (next.value == null || !next.value!.isAuthenticated) {
  //       if (ref.exists(userProfileImage(next.value!.user!.id))) {
  //         ref
  //             .read(usersServiceProvider)
  //             .clearProfilePictureCache(next.value!.user!.id);
  //         ref.read(loggerProvider).f("Invalidating user profile image");
  //         ref.invalidate(userProfileImage(next.value!.user!.id));
  //       }
  //     }
  //   },
  // );

  ref.listen(
    syncBackendNotifierProvider,
    (previous, next) {
      if (next.error == null && !next.isLoading && next.value != null) {
        // Checking if the payload is empty or still in progress (loading)
        if (!next.value!.isAvailable || next.value!.payload!.isEmpty()) return;

        for (var user in next.value!.payload!.users) {
          ref.read(usersServiceProvider).clearProfilePictureCache(user.id);

          if (ref.exists(userProfileImage(user.id))) {
            ref.read(loggerProvider).f("Invalidating user profile image");
            ref.invalidate(userProfileImage(user.id));
          }
        }
      }
    },
  );

  return 0;
});

final localUsersRepositoryProvider = Provider<LocalUsersRepository>((ref) {
  return LocalUsersRepository(ref.watch(localDbProvider));
});

final remoteUsersRepositoryProvider = Provider<RemoteUsersRepository>((ref) {
  return RemoteUsersRepository(dio: ref.watch(dioProvider));
});

final usersServiceProvider = Provider<UsersService>((ref) {
  var authState = ref.watch(authNotifierProvider).asData!.value;
  return UsersService(
      localUsersRepository: ref.watch(localUsersRepositoryProvider),
      remoteUsersRepository: ref.watch(remoteUsersRepositoryProvider),
      imageService: ref.watch(imageServiceProvider),
      picker: ref.watch(imagePickerProvider),
      authState: authState);
});

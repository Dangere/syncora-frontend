import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/image/image_providers.dart';
import 'package:syncora_frontend/core/network/syncing/sync_state.dart';
import 'package:syncora_frontend/core/network/syncing/sync_viewmodel.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/users/repositories/local_users_repository.dart';
import 'package:syncora_frontend/features/users/repositories/remote_users_repository.dart';
import 'package:syncora_frontend/features/users/services/users_service.dart';

final userProvider =
    FutureProvider.autoDispose.family<User?, int>((ref, userId) async {
  Result<User?> result = await ref.read(usersServiceProvider).getUser(userId);

  if (!result.isSuccess) {
    throw result.error!.errorObject;
  }

  return result.data;
});

final userProfileImageProvider =
    FutureProvider.family.autoDispose<Uint8List?, int>((ref, userId) async {
  Result<Uint8List?> result =
      await ref.read(usersServiceProvider).getUserProfilePicture(userId);

  if (!result.isSuccess) {
    throw result.error!.errorObject;
  }

  return result.data;
});

final usersOrchestratorProvider = Provider<void>((ref) {
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
          ref.read(loggerProvider).f("Invalidating user providers");
          ref.read(usersServiceProvider).clearProfilePictureCache(user.id);

          if (ref.exists(userProfileImageProvider(user.id))) {
            ref.invalidate(userProfileImageProvider(user.id));
          }

          if (ref.exists(userProvider(user.id))) {
            ref.invalidate(userProvider(user.id));
          }
        }
      }
    },
  );
});

class ProfilePageNotifier extends AsyncNotifier<void> {
  Future<String?> changeProfilePicture(
      AsyncFunc<XFile, Uint8List?> afterImageCropped) async {
    state = const AsyncValue.loading();

    Result<XFile?> imagePicked =
        await ref.read(imageServiceProvider).pickImage(ImageSource.gallery);

    if (!imagePicked.isSuccess) {
      ref.read(appErrorProvider.notifier).state = imagePicked.error;
      state = const AsyncValue.data(null);

      return null;
    }

    if (imagePicked.data == null) {
      ref.read(appErrorProvider.notifier).state =
          AppError(message: "No image picked");
      state = const AsyncValue.data(null);

      return null;
    }

    Uint8List? imageBytes = await afterImageCropped(imagePicked.data!);

    if (imageBytes == null) {
      ref.read(appErrorProvider.notifier).state =
          AppError(message: "No image picked");

      state = const AsyncValue.data(null);
      return null;
    }

    ref.read(loggerProvider).d("Uploading image");
    Result<String> uploadedImageUrl =
        await ref.read(imageServiceProvider).uploadImage(imageBytes);

    if (!uploadedImageUrl.isSuccess) {
      ref.read(appErrorProvider.notifier).state = uploadedImageUrl.error;
    }

    Result profilePictureUpdateResult = await ref
        .read(usersServiceProvider)
        .updateProfilePicture(uploadedImageUrl.data!);

    if (!profilePictureUpdateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state =
          profilePictureUpdateResult.error;
    }

    state = const AsyncValue.data(null);
    return uploadedImageUrl.data;
  }

  @override
  FutureOr<void> build() {}
}

// final profilePageNotifierProvider = NotifierProvider<ProfilePageNotifier,void >(ProfilePageNotifier.new);

final profilePageNotifierProvider =
    AsyncNotifierProvider<ProfilePageNotifier, void>(ProfilePageNotifier.new);

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

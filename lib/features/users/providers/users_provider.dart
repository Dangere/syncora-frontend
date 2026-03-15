import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/common/providers/connection_provider.dart';
import 'package:syncora_frontend/core/image/image_providers.dart';
import 'package:syncora_frontend/core/network/syncing/sync_state.dart';
import 'package:syncora_frontend/core/network/syncing/sync_provider.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/core/utils/app_error.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/auth_provider.dart';
import 'package:syncora_frontend/features/users/repositories/local_users_repository.dart';
import 'package:syncora_frontend/features/users/repositories/remote_users_repository.dart';
import 'package:syncora_frontend/features/users/users_service.dart';

class UserNotifier extends AsyncNotifier<void> {
  Future<void> updateUserProfile({
    String? username,
    String? firstName,
    String? lastName,
  }) async {
    if (ref.read(connectionProvider) == ConnectionStatus.disconnected) {
      return;
    }
    if (username == null && firstName == null && lastName == null) {
      ref.read(loggerProvider).w("No changes detected");
      return;
    }

    state = const AsyncValue.loading();
    ref.read(loggerProvider).i("Updating user profile");

    Result result = await ref.read(usersServiceProvider).updateProfile(
        username: username, firstName: firstName, lastName: lastName);

    if (!result.isSuccess) {
      ref.read(appErrorProvider.notifier).state = result.error;
    }
    state = const AsyncValue.data(null);
  }

  Future<String?> changeProfilePicture(
      AsyncFunc<XFile, Uint8List?> cropImageScreen, ImageSource source) async {
    if (ref.read(connectionProvider) == ConnectionStatus.disconnected) {
      return null;
    }

    state = const AsyncValue.loading();

    // Picking image
    Result<XFile?> imagePicked =
        await ref.read(imageServiceProvider).pickImage(source);

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

    // Cropping the image using the
    Uint8List? imageBytes = await cropImageScreen(imagePicked.data!);

    if (imageBytes == null) {
      ref.read(appErrorProvider.notifier).state =
          AppError(message: "No image picked");

      state = const AsyncValue.data(null);
      return null;
    }

    // Uploading image an getting the url
    Result<String> uploadedImageUrl =
        await ref.read(imageServiceProvider).uploadImage(imageBytes);

    if (!uploadedImageUrl.isSuccess) {
      ref.read(appErrorProvider.notifier).state = uploadedImageUrl.error;

      state = const AsyncValue.data(null);
      return null;
    }

    // Updating profile picture using the url
    Result profilePictureUpdateResult = await ref
        .read(usersServiceProvider)
        .updateProfilePicture(uploadedImageUrl.data!);

    if (!profilePictureUpdateResult.isSuccess) {
      ref.read(appErrorProvider.notifier).state =
          profilePictureUpdateResult.error;

      return null;
    }

    // Invalidating profile picture providers
    _invalidateProfileImageProvider(
        imageUrl: null, userId: ref.read(authProvider).value!.user!.id);

    _invalidateProfileImageProvider(
        imageUrl: uploadedImageUrl.data!,
        userId: ref.read(authProvider).value!.user!.id);

    state = const AsyncValue.data(null);
    return uploadedImageUrl.data;
  }

  Future<User?> findUser(String username) async {
    Result<User?> result =
        await ref.read(usersServiceProvider).findUser(username);

    if (!result.isSuccess) {
      ref.read(appErrorProvider.notifier).state = result.error;
      return null;
    }

    return result.data;
  }

  void _invalidateProfileImageProvider(
      {String? imageUrl, required int userId}) {
    if (ref.exists(
        userProfileImageProvider((userId: userId, imageUrl: imageUrl)))) {
      ref.invalidate(
          userProfileImageProvider((userId: userId, imageUrl: imageUrl)));
    }
  }

  @override
  FutureOr<void> build() async {
    // Updating the UI on remote user changes
    ref.listen(syncBackendProvider, (previous, next) {
      // If there is no error and the payload is not null in the next value, then we have a new payload
      if (next.error == null && !next.isLoading && next.value != null) {
        // Checking if the payload is empty or still in progress (loading)
        if (!next.value!.isAvailable || next.value!.payload!.isEmpty()) return;

        ref.read(loggerProvider).f("Invalidating user providers");
        for (var user in next.value!.payload!.users) {
          // ref.read(usersServiceProvider).clearProfilePictureCache(user.id);

          // Invalidating profile picture providers

          _invalidateProfileImageProvider(imageUrl: null, userId: user.id);
          _invalidateProfileImageProvider(
              imageUrl: user.pfpURL, userId: user.id);

          if (ref.exists(userLocalProvider(user.id)))
            ref.invalidate(userLocalProvider(user.id));
        }
      }
    });
  }
}

final userProvider =
    AsyncNotifierProvider<UserNotifier, void>(UserNotifier.new);

final userLocalProvider =
    FutureProvider.autoDispose.family<User?, int>((ref, userId) async {
  Result<User?> result =
      await ref.read(usersServiceProvider).getCachedUser(userId);

  ref.read(loggerProvider).d("Created user provider for $userId");

  ref.onDispose(() =>
      ref.read(loggerProvider).d("Auto disposing user provider of $userId"));

  if (!result.isSuccess) {
    ref.read(appErrorProvider.notifier).state = result.error;

    throw result.error!.errorObject;
  }

  return result.data;
});

// This provider is used to get the profile picture of a user, either from the cache or from a url
// One thing to note, when getting the image with imageUrl or without it, two different providers are used but reference the same image in cache
final userProfileImageProvider =
    FutureProvider.family<Uint8List?, ({int userId, String? imageUrl})>(
        (ref, user) async {
  String? url;
  // If there is not imageUrl provided, we look locally for one with the userId
  if (user.imageUrl == null) {
    url = await ref
        .read(localUsersRepositoryProvider)
        .userProfileUrl(user.userId);

    if (url == null) {
      return null;
    }
  } else {
    url = user.imageUrl!;
  }

  Result<Uint8List?> result =
      await ref.read(imageServiceProvider).getImageFromUrl(url);

  if (!result.isSuccess) {
    ref.read(appErrorProvider.notifier).state = result.error;
    return null;
  }

  return result.data;
});

final localUsersRepositoryProvider = Provider<LocalUsersRepository>((ref) {
  return LocalUsersRepository(ref.watch(localDbProvider));
});

final remoteUsersRepositoryProvider = Provider<RemoteUsersRepository>((ref) {
  return RemoteUsersRepository(dio: ref.watch(dioProvider));
});

final usersServiceProvider = Provider<UsersService>((ref) {
  var authState = ref.watch(authProvider).asData!.value;
  return UsersService(
      logger: ref.watch(loggerProvider),
      localUsersRepository: ref.watch(localUsersRepositoryProvider),
      remoteUsersRepository: ref.watch(remoteUsersRepositoryProvider),
      imageService: ref.watch(imageServiceProvider),
      picker: ref.watch(imagePickerProvider),
      authState: authState);
});

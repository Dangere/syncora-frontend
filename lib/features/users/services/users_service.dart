import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/core/image/image_service.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/users/repositories/local_users_repository.dart';
import 'package:syncora_frontend/features/users/repositories/remote_users_repository.dart';

class UsersService {
  final LocalUsersRepository _localUsersRepository;
  final RemoteUsersRepository _remoteUsersRepository;
  final ImageService _imageService;
  final AuthState _authState;

  UsersService(
      {required LocalUsersRepository localUsersRepository,
      required RemoteUsersRepository remoteUsersRepository,
      required ImageService imageService,
      required ImagePicker picker,
      required AuthState authState})
      : _localUsersRepository = localUsersRepository,
        _remoteUsersRepository = remoteUsersRepository,
        _imageService = imageService,
        _authState = authState;

  final Map<int, Uint8List?> _userProfilePictures = {};

  // Future<Result<void>> upsertUsers(List<User> users) async {
  //   try {
  //     // clear profile picture cache when users are updated
  //     Logger().f("Upserting users");

  //     for (var i = 0; i < users.length; i++) {
  //       _clearProfilePictureCache(users[i].id);
  //     }

  //     return Result.success(await _localUsersRepository.upsertUsers(users));
  //   } catch (e, stackTrace) {
  //     return Result.failure(e, stackTrace);
  //   }
  // }

  Future<Result<User?>> getUser(int id) async {
    try {
      return Result.success<User?>(await _localUsersRepository.getUser(id));
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  Future<Result<List<User>>> getUsers(List<int> ids) async {
    try {
      List<User> users = List.empty(growable: true);
      for (int id in ids) {
        User? user = await _localUsersRepository.getUser(id);
        if (user != null) {
          users.add(user);
        }
      }
      return Result.success(users);
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  // This requires context to show the crop image page
  Future<Result<void>> updateProfilePicture(String url) async {
    if (_authState.user == null || _authState.isGuest) {
      return Result.failureMessage(
          "Can't upload profile picture when not logged in");
    }
    try {
      // Updating the user profile picture using the url
      await _remoteUsersRepository.updateUserProfilePicture(url);

      // Clearing image cache for old profile picture
      clearProfilePictureCache(_authState.user!.id);

      return Result.success();
    } catch (e, stacktrace) {
      return Result.failure(e, stacktrace);
    }
  }

  // Gets the profile picture for the user with the given id using a cache
  Future<Result<Uint8List?>> getUserProfilePicture(int id) async {
    try {
      if (_userProfilePictures.containsKey(id)) {
        return Result.success(_userProfilePictures[id]);
      }

      String? imageUrl = await _localUsersRepository.userProfileUrl(id);

      // Logger().i("we got no cache for user $id, loaded Image url: $imageUrl");
      if (imageUrl == null) {
        _userProfilePictures[id] = null;
        // Logger().i("saved null for user $id");

        return Result.success(null);
      }

      Result<Uint8List> imageResult =
          await _imageService.getImageFromUrl(imageUrl);

      if (imageResult.isSuccess) {
        _userProfilePictures[id] = imageResult.data!;
      }

      return imageResult;
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  void clearProfilePictureCache(int id) {
    Logger().w("Clearing profile picture cache for user $id");
    if (_userProfilePictures.containsKey(id)) {
      _userProfilePictures.remove(id);
    }
  }
}

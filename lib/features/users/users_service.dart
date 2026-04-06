import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncora_frontend/core/network/outbox/model/enqueue_request.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_entry.dart';
import 'package:syncora_frontend/core/network/outbox/model/outbox_payload.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/auth_state.dart';
import 'package:syncora_frontend/features/users/models/user.dart';
import 'package:syncora_frontend/features/users/models/user_preferences.dart';
import 'package:syncora_frontend/features/users/repositories/local_users_repository.dart';
import 'package:syncora_frontend/features/users/repositories/remote_users_repository.dart';

class UsersService {
  final LocalUsersRepository _localUsersRepository;
  final RemoteUsersRepository _remoteUsersRepository;
  final SharedPreferences _sharedPreferences;

  final AuthState Function() _authStateFactory;
  final AsyncFunc<EnqueueRequest, Result<void>> _enqueueEntry;

  // User preferences persists even when logged out and get overridden if a logged out user changes them
  static const _userPreferencesKey = 'userPreferences';

  UsersService(this._localUsersRepository, this._remoteUsersRepository,
      this._sharedPreferences,
      {required AuthState Function() authStateFactory,
      required Future<Result<void>> Function(EnqueueRequest) enqueueEntry})
      : _authStateFactory = authStateFactory,
        _enqueueEntry = enqueueEntry;

  Future<Result<User>> findUser(String username) async {
    try {
      return Result.success<User>(
          await _remoteUsersRepository.getUser(username));
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  Future<Result<User?>> getCachedUser(int id) async {
    try {
      return Result.success<User?>(await _localUsersRepository.getUser(id));
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  Future<Result<List<User>>> getCachedUsers(List<int> ids) async {
    try {
      return Result.success<List<User>>(
          await _localUsersRepository.getUsers(ids));
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  Future<Result<List<User>>> getGroupMembers(
      int groupId, bool includeOwner) async {
    try {
      return Result.success<List<User>>(
          await _localUsersRepository.getGroupMembers(groupId, includeOwner));
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  Future<Result<void>> updateProfilePicture(String url) async {
    if (!_authStateFactory().isAuthenticated && !_authStateFactory().isGuest) {
      return Result.canceled("Can't upload profile picture when not logged in");
    }
    try {
      // Updating the user profile picture using the url
      await _remoteUsersRepository.updateUserProfilePicture(url);

      await _localUsersRepository.updateUserDetails(_authStateFactory().userId!,
          pfpUrl: url);

      return Result.success();
    } catch (e, stacktrace) {
      return Result.failure(e, stacktrace);
    }
  }

  Future<Result<void>> updateProfile(
      {String? username, String? firstName, String? lastName}) async {
    try {
      if (_authStateFactory().isAuthenticated) {
        await _remoteUsersRepository.updateUserProfile(
            username: username, firstName: firstName, lastName: lastName);
      }

      await _localUsersRepository.updateUserDetails(_authStateFactory().userId!,
          username: username, firstName: firstName, lastName: lastName);

      return Result.success();
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  Future<Result<void>> updatePreferences(
      {bool? darkMode, String? languageCode}) async {
    if (_authStateFactory().isUnauthenticated || _authStateFactory().isGuest) {
      Result<UserPreferences> preferencesResult = await getPreferences();

      if (!preferencesResult.isSuccess) return preferencesResult;

      UserPreferences newPreferences = preferencesResult.data!
          .copyWith(darkMode: darkMode, languageCode: languageCode);
      Result savePreferencesResult = await savePreferences(newPreferences);
      if (!savePreferencesResult.isSuccess) return savePreferencesResult;

      return Result.success();
    }

    Result enqueueResult = await _enqueueEntry(EnqueueRequest(
      entry: OutboxEntry.entry(
        entityId: _authStateFactory().userId!,
        entityType: OutboxEntityType.user,
        actionType: OutboxActionType.update,
        payload: UpdateUserPreferencesPayload(
          darkMode: darkMode,
          languageCode: languageCode,
        ),
      ),
      onAfterEnqueue: () async {
        Result<UserPreferences> preferencesResult = await getPreferences();

        if (!preferencesResult.isSuccess) return preferencesResult;

        UserPreferences newPreferences = preferencesResult.data!
            .copyWith(darkMode: darkMode, languageCode: languageCode);
        Result savePreferencesResult = await savePreferences(newPreferences);
        if (!savePreferencesResult.isSuccess) return savePreferencesResult;

        return Result.success();
      },
    ));
    if (!enqueueResult.isSuccess && !enqueueResult.isCancelled) {
      return Result.failure(
          enqueueResult.error!, enqueueResult.error!.stackTrace);
    }
    return Result.success();
  }

  // Retrieves the global user preferences or defaults if theres none yet
  Future<Result<UserPreferences>> getPreferences() async {
    try {
      String? preferences = _sharedPreferences.getString(_userPreferencesKey);

      if (preferences != null) {
        return Result.success(
            UserPreferences.fromJson(jsonDecode(preferences)));
      } else {
        // If no preferences are found, return the defaults
        UserPreferences defaultPreferences = UserPreferences.defaults();
        await savePreferences(defaultPreferences);
        return Result.success(defaultPreferences);
      }
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  // Saves the global user preferences
  Future<Result<void>> savePreferences(UserPreferences preferences) async {
    try {
      _sharedPreferences.setString(
          _userPreferencesKey, jsonEncode(preferences));
      return Result.success();
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  // Saves the main user object
  Future<Result<void>> saveUser(User user) async {
    try {
      await _localUsersRepository.upsertUsers([user]);
      return Result.success();
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }
}

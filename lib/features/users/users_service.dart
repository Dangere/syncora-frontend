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
  final AuthState _authState;

  UsersService(
      {required LocalUsersRepository localUsersRepository,
      required RemoteUsersRepository remoteUsersRepository,
      required ImageService imageService,
      required ImagePicker picker,
      required AuthState authState,
      required Logger logger})
      : _localUsersRepository = localUsersRepository,
        _remoteUsersRepository = remoteUsersRepository,
        _authState = authState;

  // final Map<int, Uint8List?> _userProfilePictures = {};

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

  Future<Result<List<User>>> getGroupMembers(int groupId) async {
    try {
      return Result.success<List<User>>(
          await _localUsersRepository.getGroupMembers(groupId));
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }

  Future<Result<void>> updateProfilePicture(String url) async {
    if (_authState.user == null || _authState.isGuest) {
      return Result.failureMessage(
          "Can't upload profile picture when not logged in");
    }
    try {
      // Updating the user profile picture using the url
      await _remoteUsersRepository.updateUserProfilePicture(url);

      return Result.success();
    } catch (e, stacktrace) {
      return Result.failure(e, stacktrace);
    }
  }

  Future<Result<void>> updateProfile(
      {String? username, String? firstName, String? lastName}) async {
    try {
      await _remoteUsersRepository.updateUserProfile(
          username: username, firstName: firstName, lastName: lastName);
      return Result.success();
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }
  }
}

import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/users/repositories/local_users_repository.dart';

class UsersService {
  final LocalUsersRepository _localUsersRepository;

  UsersService({required localUsersRepository})
      : _localUsersRepository = localUsersRepository;

  Future<Result<void>> deleteDiscarded() {
    throw UnimplementedError();
  }

  Future<Result<void>> upsertUsers(List<User> users) async {
    try {
      return Result.success(await _localUsersRepository.upsertUsers(users));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<User>> getUser(int id) async {
    try {
      return Result.success(await _localUsersRepository.getUser(id));
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }

  Future<Result<List<User>>> getUsers(List<int> ids) async {
    try {
      List<User> users = List.empty(growable: true);
      for (int id in ids) {
        users.add(await _localUsersRepository.getUser(id));
      }
      return Result.success(users);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }
}

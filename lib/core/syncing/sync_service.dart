import 'package:dio/dio.dart';
import 'package:syncora_frontend/core/syncing/sync_repository.dart';
import 'package:syncora_frontend/core/utils/error_mapper.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/groups/models/group.dart';
import 'package:syncora_frontend/features/groups/repositories/local_groups_repository.dart';
import 'package:syncora_frontend/features/groups/repositories/remote_groups_repository.dart';
import 'package:syncora_frontend/features/users/repositories/local_users_repository.dart';
import 'package:syncora_frontend/features/users/repositories/remote_users_repository.dart';

class SyncService {
  final Dio _dio;
  final LocalGroupsRepository _localGroupsRepository;
  final RemoteGroupsRepository _remoteGroupsRepository;

  final LocalUsersRepository _localUsersRepository;
  final RemoteUsersRepository _remoteUsersRepository;

  final SyncRepository _syncRepository;

  SyncService(
      {required Dio dio,
      required LocalGroupsRepository localGroupRepository,
      required RemoteGroupsRepository remoteGroupRepository,
      required LocalUsersRepository localUsersRepository,
      required RemoteUsersRepository remoteUsersRepository,
      required SyncRepository syncRepository})
      : _dio = dio,
        _localGroupsRepository = localGroupRepository,
        _remoteGroupsRepository = remoteGroupRepository,
        _localUsersRepository = localUsersRepository,
        _remoteUsersRepository = remoteUsersRepository,
        _syncRepository = syncRepository;

  Future<Result<void>> syncFromServer() async {
    // try {
    //   List<User> users = await _remoteUsersRepository.getAllUsers();
    //   for (var i = 0; i < users.length; i++) {
    //     _localUsersRepository.upsertUser(users[i]);
    //   }
    // } catch (e, stackTrace) {
    //   return Result.failure(ErrorMapper.map(e, stackTrace));
    // }

    // try {
    //   List<Group> groups = await _remoteGroupsRepository.getAllGroups();
    //   for (var i = 0; i < groups.length; i++) {
    //     _localGroupsRepository.upsertGroup(groups[i].toJson());
    //   }
    // } catch (e, stackTrace) {
    //   return Result.failure(ErrorMapper.map(e, stackTrace));
    // }

    try {
      Map<String, dynamic> payload = await _syncRepository.sync("2022-01-01");

      return Result.success(payload);
    } catch (e, stackTrace) {
      return Result.failure(ErrorMapper.map(e, stackTrace));
    }
  }
}

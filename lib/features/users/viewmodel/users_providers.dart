import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/features/users/repositories/local_users_repository.dart';
import 'package:syncora_frontend/features/users/services/users_service.dart';

final localUsersRepositoryProvider = Provider<LocalUsersRepository>((ref) {
  return LocalUsersRepository(ref.watch(localDbProvider));
});

final usersServiceProvider = Provider<UsersService>((ref) {
  return UsersService(
      localUsersRepository: ref.watch(localUsersRepositoryProvider));
});

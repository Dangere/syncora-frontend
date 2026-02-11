import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/image/image_provider.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/users/repositories/local_users_repository.dart';
import 'package:syncora_frontend/features/users/repositories/remote_users_repository.dart';
import 'package:syncora_frontend/features/users/services/users_service.dart';

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
      authState: authState);
});

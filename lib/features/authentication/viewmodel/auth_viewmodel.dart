import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/authentication/repository/auth_repository.dart';
import 'package:syncora_frontend/features/authentication/services/auth_service.dart';

class AuthNotifier extends Notifier<User?> {
  late final AuthService _authService;

  void loginWithEmailAndPassword(String email, String password) async {
    if (state != null) return;

    Result<User> result =
        await _authService.loginWithEmailAndPassword(email, password);
    if (result.isSuccess) {
      state = result.data;
    } else {
      print(result.error);
    }
  }

  void registerWithEmailAndPassword(
      String email, String username, String password) async {
    if (state != null) return;

    Result<User> result = await _authService.registerWithEmailAndPassword(
        email, username, password);

    if (result.isSuccess) {
      state = result.data;
    } else {
      print(result.error);
    }
  }

  void logout() async {
    state = null;
  }

  @override
  User? build() {
    _authService = ref.read(authServiceProvider);
    return null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

final dioProvider = Provider<Dio>((ref) => Dio());

final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => AuthRepository(dio: ref.read(dioProvider)));

final authServiceProvider = Provider<AuthService>(
    (ref) => AuthService(authRepository: ref.read(authRepositoryProvider)));

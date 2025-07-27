import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/features/authentication/view/pages/login_page.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/groups/view/page/groups_page.dart';
import 'package:syncora_frontend/features/home/view/page/home_page.dart';

final routeProvider = Provider<GoRouter>((ref) {
  bool isLogged = ref.watch(isLoggedProvider);

  Logger logger = ref.read(loggerProvider);
  logger.w('Refreshing routes');

  return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          name:
              'home', // Optional, add name to your routes. Allows you navigate by name instead of path
          path: '/',

          builder: (context, state) {
            return const HomePage(
              title: "Home",
            );
          },
        ),
        GoRoute(
          name: 'login',
          path: '/login',
          builder: (context, state) {
            return const LoginPage();
          },
        ),
        GoRoute(
          name: 'groups',
          path: '/groups',
          builder: (context, state) {
            return const GroupsPage();
          },
        ),
      ],
      redirect: (context, state) {
        if (!isLogged && state.fullPath != "/login") {
          logger.d(state.fullPath);

          return '/login';
        }

        return null;
      });
});

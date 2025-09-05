import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/features/authentication/view/pages/login_page.dart';
import 'package:syncora_frontend/features/authentication/view/pages/register_page.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/groups/view/page/group_view_page.dart';
// import 'package:syncora_frontend/features/groups/view/page/groups_page.dart';
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
          name: 'register',
          path: '/register',
          builder: (context, state) {
            return const RegisterPage();
          },
        ),
        GoRoute(
          name: 'group-view',
          path: '/group-view/:groupId',
          builder: (context, state) {
            int groupId = int.parse(state.pathParameters['groupId']!);

            return GroupViewPage(
              groupId: groupId,
            );
          },
        ),
      ],
      redirect: (context, state) {
        if (!isLogged &&
            state.fullPath != "/login" &&
            state.fullPath != "/register") {
          logger.d(
              "You were on ${state.fullPath} and getting redirected to login page");
          return '/login';
        }

        return null;
      });
});

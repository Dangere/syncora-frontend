import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/features/authentication/view/pages/login_page.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/home/view/page/home_page.dart';

final routeProvider = Provider<GoRouter>((ref) {
  bool isLogged = ref.watch(authProvider).user != null;

  return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          name:
              'home', // Optional, add name to your routes. Allows you navigate by name instead of path
          path: '/',

          builder: (context, state) {
            return const HomeScreen(
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
      ],
      redirect: (context, state) {
        if (!isLogged) return '/login';
        return null;
      });
});

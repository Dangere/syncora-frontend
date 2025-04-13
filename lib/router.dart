import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/features/home/view/page/home_screen.dart';

// GoRouter configuration
final router = GoRouter(
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
  ],
);

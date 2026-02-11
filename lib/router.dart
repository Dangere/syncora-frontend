import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:syncora_frontend/core/typedef.dart';
import 'package:syncora_frontend/features/authentication/view/pages/password_reset_page.dart';
import 'package:syncora_frontend/features/authentication/view/pages/sign_in_page.dart';
import 'package:syncora_frontend/features/authentication/view/pages/sign_up_page.dart';
import 'package:syncora_frontend/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:syncora_frontend/features/dashboard/view/pages/dashboard_page.dart';
import 'package:syncora_frontend/features/groups/view/page/group_view_page.dart';
import 'package:syncora_frontend/features/onboarding/view/onboarding_page.dart';
import 'package:syncora_frontend/features/settings/view/settings_page.dart';

class MyNavObserver extends NavigatorObserver {
  MyNavObserver({required this.ref, required this.onPush, required this.onPop});
  final Ref ref;
  final Func<String, void> onPush;
  final Func<String, void> onPop;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    onPush(route.settings.name ?? '');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);

    onPop(route.settings.name ?? '');
  }
}

class RouteNotifier extends Notifier<GoRouter> {
  final _routeController = StreamController<String>();

  Stream<String> get dataStream => _routeController.stream;

  @override
  GoRouter build() {
    // ref.onDispose(
    //   () {
    //     _routeController.close();
    //   },
    // );

    bool isLogged = ref.watch(isLoggedProvider);

    Logger logger = ref.read(loggerProvider);
    logger.w('Refreshing routes, isLogged: $isLogged');

    // const publicRoutes = {
    //   'login',
    //   'register',
    //   'reset-password',
    // };

    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
            name:
                'home', // Optional, add name to your routes. Allows you navigate by name instead of path
            path: '/',
            builder: (context, state) {
              return const DashboardPage(
                  // title: "Home",
                  );
            },
            routes: [
              GoRoute(
                name: 'settings',
                path: 'settings',
                builder: (context, state) {
                  return const SettingsPage();
                },
              ),
            ]),
        GoRoute(
            name: 'onboarding',
            path: '/onboarding',
            builder: (context, state) {
              return const OnboardingPage();
            },
            routes: [
              GoRoute(
                name: 'sign-up',
                path: 'sign-up',
                builder: (context, state) {
                  return const SignUpPage();
                },
              ),
              GoRoute(
                  name: 'sign-in',
                  path: 'sign-in',
                  builder: (context, state) {
                    return const SignInPage();
                  },
                  routes: [
                    GoRoute(
                      name: 'reset-password',
                      path: 'reset-password',
                      builder: (context, state) {
                        return const PasswordResetPage();
                      },
                    ),
                  ]),
            ]),
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
      // TODO: Check the public routes and implement them in the redirection
      redirect: (context, state) {
        if (!isLogged &&
            state.fullPath != "/onboarding/sign-in" &&
            state.fullPath != "/onboarding/sign-in/reset-password" &&
            state.fullPath != "/onboarding/sign-up" &&
            state.fullPath != "/onboarding") {
          logger.d(
              "You were on ${state.fullPath} and getting redirected to login page");
          return '/onboarding';
        }

        return null;
      },
      observers: [
        MyNavObserver(
          ref: ref,
          onPop: (arg) {
            _routeController.add(state.state.name ?? '');
          },
          onPush: (arg) {
            _routeController.add(state.state.name ?? '');
          },
        )
      ],
    );
  }
}

final routeProvider =
    NotifierProvider<RouteNotifier, GoRouter>(RouteNotifier.new);

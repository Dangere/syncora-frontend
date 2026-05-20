import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/providers/app_init_provider.dart';
import 'package:syncora_frontend/core/utils/snack_bar_alerts.dart';
import 'package:transparent_image/transparent_image.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Object? error;

  void goToApp() async {
    await Future.delayed(Duration(seconds: 3));

    if (mounted) context.pushReplacement('/');
  }

  @override
  Widget build(BuildContext context) {
    SnackBarAlerts.registerNotificationListener(ref, context);

    final lightMode = Theme.of(context).brightness == Brightness.light;
    var initialize = ref.watch(appInitializeProvider);

    if (initialize.hasError) {
      error = initialize.error;
    }
    if (initialize.hasValue && !initialize.hasError) {
      goToApp();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // Positioned.fill(
          //   child: FadeInImage(
          //     width: double.infinity,
          //     alignment: Alignment.topCenter,
          //     fit: BoxFit.fitWidth,
          //     placeholder: MemoryImage(kTransparentImage),
          //     image: const AssetImage("assets/images/background_dashboard.png"),
          //   ),
          // ),
          // Positioned.fill(
          //   child: FadeInImage(
          //     width: double.infinity,
          //     alignment: Alignment.topCenter,
          //     fit: BoxFit.fitWidth,
          //     placeholder: MemoryImage(kTransparentImage),
          //     image: const AssetImage(
          //         "assets/images/background_dashboard_effect.png"),
          //   ),
          // ),
          Positioned.fill(
            child: FadeInImage(
              width: double.infinity,
              alignment: Alignment.topCenter,
              fit: BoxFit.fitWidth,
              placeholder: MemoryImage(kTransparentImage),
              image: AssetImage(
                  "assets/images/${lightMode ? "onboarding_background_light" : "onboarding_background_dark"}.png"),
            ),
          ),
          if (error != null)
            Center(
              child: Text(
                error.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (error == null)
            Center(
              child: Container(
                alignment: Alignment.center,
                width: 205 - (MediaQuery.of(context).size.height * 0.01),
                height: 205 - (MediaQuery.of(context).size.height * 0.01),
                decoration: BoxDecoration(
                  color: lightMode
                      ? Colors.white
                      : Colors.deepPurple.shade900.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.all(Radius.circular(32)),
                ),
                child: SizedBox.square(
                  child: FadeInImage(
                    width: double.infinity,
                    alignment: Alignment.topCenter,
                    color: lightMode
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.primary,
                    height: 115,
                    placeholder: MemoryImage(kTransparentImage),
                    image: const AssetImage("assets/logos/syncora-logo.png"),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

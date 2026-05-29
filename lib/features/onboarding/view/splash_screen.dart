import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/providers/app_init_provider.dart';
import 'package:transparent_image/transparent_image.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Object? error;

  void goToApp() async {
    // Delay can be removed for faster loading
    await Future.delayed(Duration(seconds: 3));
    if (mounted) context.pushReplacement('/');
  }

  @override
  Widget build(BuildContext context) {
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
                      : Color(0xFF1A182D).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.all(Radius.circular(32)),
                ),
                child: SizedBox.square(
                  child: SvgPicture.asset(
                    "assets/logos/syncora-logo.svg",
                    height: 115,
                    colorFilter: ColorFilter.mode(
                        lightMode
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.primary,
                        BlendMode.srcIn),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

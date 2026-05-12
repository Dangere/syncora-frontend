import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:syncora_frontend/common/providers/app_init_provider.dart';
import 'package:syncora_frontend/common/providers/common_providers.dart';
import 'package:transparent_image/transparent_image.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    ref.read(appInitializeProvider.future).then((_) async {
      await Future.delayed(Duration(seconds: 3));

      if (mounted) context.pushReplacement('/');
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final lightMode = Theme.of(context).brightness == Brightness.light;

    // once loading is done navigate to the home screen

    print("building splash screen");

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: FadeInImage(
              width: double.infinity,
              alignment: Alignment.topCenter,
              fit: BoxFit.fitWidth,
              placeholder: MemoryImage(kTransparentImage),
              image: const AssetImage("assets/images/background_dashboard.png"),
            ),
          ),
          Positioned.fill(
            child: FadeInImage(
              width: double.infinity,
              alignment: Alignment.topCenter,
              fit: BoxFit.fitWidth,
              placeholder: MemoryImage(kTransparentImage),
              image: const AssetImage(
                  "assets/images/background_dashboard_effect.png"),
            ),
          ),
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

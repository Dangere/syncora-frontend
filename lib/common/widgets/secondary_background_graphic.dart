import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

class SecondaryBackgroundGraphic extends StatelessWidget {
  const SecondaryBackgroundGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    final lightMode = Theme.of(context).brightness == Brightness.light;

    return Positioned.fill(
      child: FadeInImage(
        width: double.infinity,
        alignment: Alignment.topCenter,
        fit: BoxFit.fitWidth,
        placeholder: MemoryImage(kTransparentImage),
        image: AssetImage(
            "assets/images/${lightMode ? "onboarding_background_light" : "onboarding_background_dark"}.png"),
      ),
    );
  }
}

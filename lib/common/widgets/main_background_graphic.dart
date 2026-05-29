import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

class MainBackgroundGraphic extends StatelessWidget {
  const MainBackgroundGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    final lightMode = Theme.of(context).brightness == Brightness.light;

    return Stack(
      children: [
        // BACKGROUND GRAPHIC COLORS
        Positioned.fill(
          child: FadeInImage(
            width: double.infinity,
            alignment: Alignment.topCenter,
            fit: BoxFit.fitWidth,
            placeholder: MemoryImage(kTransparentImage),
            image: AssetImage(
                "assets/images/dashboard_background_effect_${lightMode ? "light" : "dark"}.png"),
          ),
        ),
        //BACKGROUND GRAPHIC
        Positioned.fill(
          child: FadeInImage(
            width: double.infinity,
            alignment: Alignment.topCenter,
            fit: BoxFit.fitWidth,
            placeholder: MemoryImage(kTransparentImage),
            image: AssetImage(
                "assets/images/dashboard_background_${lightMode ? "light" : "dark"}.png"),
          ),
        ),
      ],
    );
  }
}

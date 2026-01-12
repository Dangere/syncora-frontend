import 'package:flutter/material.dart';

enum AppButtonVariant {
  primary,
  secondary,
  glow,
}

/// The most buttons will call from
class AppButton extends StatelessWidget {
  final AppButtonVariant variant;
  final VoidCallback onPressed;
  final Widget child;
  final double height;
  final double width;

  const AppButton({
    super.key,
    required this.variant,
    required this.onPressed,
    required this.child,
    this.height = 56,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ButtonStyle style = switch (variant) {
      AppButtonVariant.primary => ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 2,
        ),
      AppButtonVariant.secondary => ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.primary,
          side: BorderSide(color: theme.colorScheme.primary),
          elevation: 0,
        ),
      AppButtonVariant.glow => ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.primary,
          elevation: 0,
        ),
    };

    return Container(
      height: height,
      width: width,
      decoration: variant != AppButtonVariant.glow
          ? null
          : BoxDecoration(
              borderRadius:
                  BorderRadius.circular(8), // Match your Figma corner radius
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary
                      .withOpacity(0.28), // The color of the glow
                  offset: const Offset(0, 4),
                  blurRadius: 16, // The intensity of the glow
                  spreadRadius: 0,
                ),
              ],
            ),
      child: ElevatedButton(
        style: style,
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}

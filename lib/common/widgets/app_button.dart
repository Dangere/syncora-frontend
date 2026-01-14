import 'package:flutter/material.dart';

enum AppButtonVariant {
  primary,
  secondary,
  glow,
}

/// The most buttons will call from
class AppButton extends StatelessWidget {
  final AppButtonVariant variant;
  final bool disabled;
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
    this.disabled = false,
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

    final ButtonStyle disabledStyle = ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.onSurface,
      foregroundColor: theme.colorScheme.outline,
      elevation: 0,
    );

    return Container(
      height: height,
      width: width,
      decoration: (variant == AppButtonVariant.glow && !disabled)
          ? BoxDecoration(
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
            )
          : null,
      child: AbsorbPointer(
        absorbing: disabled,
        child: ElevatedButton(
          style: disabled ? disabledStyle : style,
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
  }
}

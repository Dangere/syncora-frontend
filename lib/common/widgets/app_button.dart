import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncora_frontend/common/themes/app_theme.dart';

enum AppButtonVariant { primary, secondary, glow, dropdown, settings, logout }

/// The most buttons will call from
class AppButton extends StatelessWidget {
  final AppButtonVariant variant;
  final bool disabled;
  final VoidCallback onPressed;
  final Widget child;
  final double width;
  final double fontSize;
  final bool highlighted;

  const AppButton(
      {super.key,
      required this.variant,
      required this.onPressed,
      required this.child,
      this.width = double.infinity,
      this.disabled = false,
      this.fontSize = 20.0,
      this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontFamily = Theme.of(context).textTheme.bodyLarge!.fontFamily;
    final ButtonStyle style = switch (variant) {
      AppButtonVariant.primary => ElevatedButton.styleFrom(
          // This applied to texts nested but not color wise
          textStyle: TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w700),
          backgroundColor: theme.colorScheme.primary,
          // Text, icons nested are colored here
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 2,
        ),
      AppButtonVariant.secondary => ElevatedButton.styleFrom(
          textStyle: TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w700),
          backgroundColor: theme.colorScheme.surfaceContainer,
          foregroundColor: theme.colorScheme.primary,
          side: BorderSide(color: theme.colorScheme.primary),
          elevation: 0,
        ),
      AppButtonVariant.glow => ElevatedButton.styleFrom(
          textStyle: TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w700),
          backgroundColor: theme.colorScheme.surfaceContainer,
          foregroundColor: theme.colorScheme.primary,
          elevation: 0,
        ),
      AppButtonVariant.dropdown => ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          textStyle: TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w700),
          backgroundColor: theme.colorScheme.surfaceContainer,
          foregroundColor: theme.colorScheme.outline,
          side: BorderSide(
              width: 0.8,
              color: highlighted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.scrim.withValues(alpha: 0.4)),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      AppButtonVariant.settings => ElevatedButton.styleFrom(
          textStyle: TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w700),
          backgroundColor: theme.colorScheme.surfaceContainer,
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
      AppButtonVariant.logout => ElevatedButton.styleFrom(
          textStyle: TextStyle(
              color: theme.colorScheme.error,
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w700),
          backgroundColor: theme.colorScheme.error,
          foregroundColor: theme.colorScheme.onError,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
    };

    final double height = switch (variant) {
      AppButtonVariant.primary => 56.0,
      AppButtonVariant.secondary => 56.0,
      AppButtonVariant.glow => 56.0,
      AppButtonVariant.dropdown => 52.0,
      AppButtonVariant.settings => 66,
      AppButtonVariant.logout => 66,
    };

    final ButtonStyle disabledStyle = style.copyWith(
      backgroundColor: WidgetStateProperty.all(theme.colorScheme.onSurface),
      foregroundColor: WidgetStateProperty.all(theme.colorScheme.outline),
      elevation: WidgetStateProperty.all(0),
      side: WidgetStateProperty.all(null),
    );

    List<BoxShadow> shadows = [
      if (variant == AppButtonVariant.glow) AppShadow.shadow1(context),
      if (variant == AppButtonVariant.dropdown && highlighted)
        AppShadow.shadow1(context),
      if (variant == AppButtonVariant.settings) AppShadow.shadow0(context),
    ];

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(8), // Match your Figma corner radius
        boxShadow: shadows,
      ),
      child: AbsorbPointer(
        absorbing: disabled,
        child: ElevatedButton(
          style: disabled ? disabledStyle : style,
          onPressed: onPressed,
          child: variant != AppButtonVariant.dropdown
              ? child
              : Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    child,
                  ],
                ),
        ),
      ),
    );
  }
}

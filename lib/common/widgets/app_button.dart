import 'package:flutter/material.dart';
import 'package:syncora_frontend/common/themes/app_theme.dart';

enum AppButtonVariant {
  primary,
  secondary,
  glow,
  dropdown,
}

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

    final ButtonStyle style = switch (variant) {
      AppButtonVariant.primary => ElevatedButton.styleFrom(
          textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 2,
        ),
      AppButtonVariant.secondary => ElevatedButton.styleFrom(
          textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.primary,
          side: BorderSide(color: theme.colorScheme.primary),
          elevation: 0,
        ),
      AppButtonVariant.glow => ElevatedButton.styleFrom(
          textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.primary,
          elevation: 0,
        ),
      AppButtonVariant.dropdown => ElevatedButton.styleFrom(
          textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.outline,
          side: BorderSide(
              width: 0.8,
              color: highlighted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.scrim.withOpacity(0.4)),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
    };

    final double height = switch (variant) {
      AppButtonVariant.primary => 56.0,
      AppButtonVariant.secondary => 56.0,
      AppButtonVariant.glow => 56.0,
      AppButtonVariant.dropdown => 52.0
    };

    final ButtonStyle disabledStyle = style.copyWith(
      backgroundColor:
          MaterialStateProperty.all<Color>(theme.colorScheme.onSurface),
      foregroundColor:
          MaterialStateProperty.all<Color>(theme.colorScheme.outline),
      elevation: MaterialStateProperty.all<double>(0),
      side: MaterialStateProperty.all<BorderSide?>(null),
    );

    bool hasShadow = ((variant == AppButtonVariant.glow ||
            (variant == AppButtonVariant.dropdown && highlighted)) &&
        !disabled);

    return Container(
      height: height,
      width: width,
      decoration: hasShadow
          ? BoxDecoration(
              borderRadius:
                  BorderRadius.circular(8), // Match your Figma corner radius
              boxShadow: [AppShadow.shadow1(context)],
            )
          : null,
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncora_frontend/common/themes/app_theme.dart';

// enum AppButtonVariant {
//   wide,
//   outlined,
//   glow,
//   dropdown,
//   settings,
//   logout,

// }
enum AppButtonSize {
  ///  66.0 height
  huge,

  /// 56.0 height
  large,

  /// 52.0 height
  medium,

  /// 40.0 height
  small,

  /// 42.0 height
  icon,
}

enum AppButtonStyle {
  filled,
  outlined,
  dropdown,
  glow,
}

enum AppButtonIntent {
  primary,
  secondary,
  normal,
  destructive,
  warning,
}

/// The most buttons will call from
class AppButton extends StatelessWidget {
  // final AppButtonVariant variant;
  final AppButtonSize size;
  final AppButtonStyle style;
  final AppButtonIntent intent;
  final EdgeInsetsGeometry padding;
  final bool disabled;
  final bool highlighted;
  final double? width;
  final double fontSize;
  final VoidCallback onPressed;
  final Widget child;

  const AppButton({
    super.key,
    required this.size,
    required this.style,
    this.intent = AppButtonIntent.normal,
    this.padding = const EdgeInsets.all(0),
    this.width = double.infinity,
    this.disabled = false,
    this.highlighted = false,
    this.fontSize = 20.0,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontFamily = Theme.of(context).textTheme.bodyLarge!.fontFamily;
    final double roundedCorner = switch (size) {
      AppButtonSize.huge => 20.0,
      AppButtonSize.large => 17.0,
      AppButtonSize.medium => 20.0,
      AppButtonSize.small => 60.0,
      AppButtonSize.icon => 8.0,
    };

    final double contentHorizontalPadding = switch (size) {
      AppButtonSize.huge => 16.0,
      AppButtonSize.large => 16.0,
      AppButtonSize.medium => 16.0,
      AppButtonSize.small => 14.0,
      AppButtonSize.icon => 16.0,
    };

    final double height = switch (size) {
      AppButtonSize.huge => 66.0,
      AppButtonSize.large => 56.0,
      AppButtonSize.medium => 52.0,
      AppButtonSize.small => 40.0,
      AppButtonSize.icon => 42,
    };

    // Controls the shape
    final ButtonStyle buttonShape = switch (style) {
      AppButtonStyle.filled => ElevatedButton.styleFrom(
          // This applied to texts nested but not color wise
          textStyle: TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w700),
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: contentHorizontalPadding),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(roundedCorner)),
        ),
      AppButtonStyle.outlined => ElevatedButton.styleFrom(
          textStyle: TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w700),
          side: BorderSide(color: theme.colorScheme.primary),
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: contentHorizontalPadding),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(roundedCorner)),
        ),
      AppButtonStyle.glow => ElevatedButton.styleFrom(
          textStyle: TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w700),
          backgroundColor: theme.colorScheme.surfaceContainer,
          foregroundColor: theme.colorScheme.primary,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: contentHorizontalPadding),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(roundedCorner)),
        ),
      AppButtonStyle.dropdown => ElevatedButton.styleFrom(
          shadowColor: Colors.transparent,
          textStyle: TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w700),
          foregroundColor: theme.colorScheme.outline,
          side: BorderSide(
              width: 0.8,
              color: highlighted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.scrim.withValues(alpha: 0.4)),
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: contentHorizontalPadding),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(roundedCorner)),
        )
    };

    final ButtonStyle buttonStyle = switch (intent) {
      AppButtonIntent.primary => buttonShape,
      AppButtonIntent.normal => buttonShape.copyWith(
          backgroundColor:
              WidgetStateProperty.all(theme.colorScheme.surfaceContainer),
          foregroundColor:
              WidgetStateProperty.all(theme.colorScheme.onSurfaceVariant),
          // elevation: WidgetStateProperty.all(0),
        ),
      AppButtonIntent.destructive => buttonShape.copyWith(
          backgroundColor: WidgetStateProperty.all(theme.colorScheme.error),
          foregroundColor: WidgetStateProperty.all(theme.colorScheme.onError),
        ),
      AppButtonIntent.warning => buttonShape.copyWith(
          backgroundColor: WidgetStateProperty.all(theme.colorScheme.error),
          foregroundColor: WidgetStateProperty.all(theme.colorScheme.onError),
        ),
      // TODO: Handle this case.
      AppButtonIntent.secondary => buttonShape.copyWith(
          backgroundColor: WidgetStateProperty.all(theme.colorScheme.secondary),
          foregroundColor:
              WidgetStateProperty.all(theme.colorScheme.onSecondary),
          // elevation: WidgetStateProperty.all(0),
        ),
    };

    final ButtonStyle disabledStyle = buttonShape.copyWith(
      backgroundColor: WidgetStateProperty.all(theme.colorScheme.onSurface),
      foregroundColor: WidgetStateProperty.all(theme.colorScheme.outline),
      elevation: WidgetStateProperty.all(0),
      side: WidgetStateProperty.all(null),
    );

    List<BoxShadow> shadows = [
      // AppShadow.shadow1(context),
      if (style == AppButtonStyle.glow) AppShadow.shadow1(context),
      if (style != AppButtonStyle.glow && style != AppButtonStyle.dropdown)
        AppShadow.shadow0(context),
      if (style == AppButtonStyle.dropdown && highlighted)
        AppShadow.shadow0(context),

      // if (style == AppButtonStyle.ghost) AppShadow.shadow0(context),

      // if (variant == AppButtonVariant.dropdown && highlighted)
      // AppShadow.shadow0(context),
      // if (variant == AppButtonVariant.settings) AppShadow.shadow0(context),
    ];

    return Padding(
      padding: padding,
      child: Container(
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
            style: disabled ? disabledStyle : buttonStyle,
            onPressed: onPressed,
            child: child,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AppSpacing {
  /// size of 4 lp
  static const double xs = 4;

  /// size of 8 lp
  static const double sm = 8;

  /// size of 16 lp
  static const double md = 16;

  /// size of 24 lp
  static const double lg = 24;

  /// size of 32 lp
  static const double xl = 32;

  /// size of 48 lp
  static const double xxl = 48;

  static const EdgeInsets paddingAllSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingHorizontalMd =
      EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg =
      EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingVerticalMd =
      EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLg =
      EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVerticalXl =
      EdgeInsets.symmetric(vertical: xl);
  static const EdgeInsets paddingVerticalXxl =
      EdgeInsets.symmetric(vertical: xxl);
  static const SizedBox horizontalSpaceSm = SizedBox(width: sm);
  static const SizedBox horizontalSpaceMd = SizedBox(width: md);
  static const SizedBox horizontalSpaceLg = SizedBox(width: lg);

  static const SizedBox verticalSpaceSm = SizedBox(height: sm);
  static const SizedBox verticalSpaceMd = SizedBox(height: md);
  static const SizedBox verticalSpaceLg = SizedBox(height: lg);
}

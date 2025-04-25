import 'package:flutter/material.dart';

class AppSpacing {
  /// size of 4 px
  static const double xs = 4;

  /// size of 8 px
  static const double sm = 8;

  /// size of 16 px
  static const double md = 16;

  /// size of 24 px
  static const double lg = 24;

  /// size of 32 px
  static const double xl = 32;

  /// size of 48 px
  static const double xxl = 48;

  static const EdgeInsets paddingAllSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingHorizontalMd =
      EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingVerticalLg =
      EdgeInsets.symmetric(vertical: lg);

  static const SizedBox horizontalSpaceSm = SizedBox(height: sm);
  static const SizedBox horizontalSpaceMd = SizedBox(height: md);
  static const SizedBox horizontalSpaceLg = SizedBox(height: lg);
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ColorScheme lightColorScheme = ColorScheme.fromSeed(
          seedColor: Color(0xFFB284BE), brightness: Brightness.light)
      .copyWith(
    primary: Color(0xFFB284BE),
  );
  static ColorScheme darkColorScheme = ColorScheme.fromSeed(
          seedColor: Color(0xFFB284BE), brightness: Brightness.dark)
      .copyWith(
    primary: Color(0xFFB284BE),
  );

  static ThemeData appLightTheme = ThemeData(
    fontFamily: GoogleFonts.cairo().fontFamily,
    useMaterial3: true,
    colorScheme: lightColorScheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
          // backgroundColor: lightColorScheme.primary,
          ),
    ),
  );
  static ThemeData appDarkTheme = ThemeData(
    fontFamily: GoogleFonts.cairo().fontFamily,
    useMaterial3: true,
    colorScheme: darkColorScheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkColorScheme.primary,
      ),
    ),
  );
}

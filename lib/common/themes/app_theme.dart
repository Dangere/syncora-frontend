import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ColorScheme lightColorScheme =
      ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light)
          .copyWith(
    primary: Colors.blue,
  );
  static ColorScheme darkColorScheme =
      ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark)
          .copyWith(
    primary: Colors.blue,
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

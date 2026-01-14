import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppGrays {
  /// 2E2E2E
  static const gray900 = Color(0xFF2E2E2E);

  /// 4E4E4E
  static const gray700 = Color(0xFF4E4E4E);

  /// 6E6E6E
  static const gray500 = Color(0xFF6E6E6E);

  /// 8E8E8E
  static const gray300 = Color(0xFF8E8E8E);

  /// b8b7bb
  static const gray200 = Color(0xFFb8b7bb);
}

class AppTheme {
  static ColorScheme lightColorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF7265E3),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFBCB5F7),
    onSecondary: Color(0xFF4E4E4E),
    error: Color(0xFFE54D52),
    onError: Color(0xFFFFFFFF),
    background: Color(0xFFFDFCFF),
    surface: Color(0xFFFFFFFF),

    // TEXT – primary & secondary
    onSurface: AppGrays.gray900, // main text (titles, primary body)
    onBackground: AppGrays.gray900,

    onSurfaceVariant: AppGrays.gray700, // secondary text, descriptions
    outline: AppGrays.gray500, // muted text, metadata, captions
    outlineVariant: AppGrays.gray300, // disabled text, hints, placeholders

    // Optional
    scrim: AppGrays.gray200, // very low emphasis / separators
  );
  static ColorScheme darkColorScheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF5349B4),
      onPrimary: Color(0xFFEAEAEA),
      secondary: Color(0xFF28234F),
      onSecondary: Color(0xFFC5C5C5),
      error: Color(0xFFB82426),
      onError: Color(0xFFEAEAEA),
      background: Color(0xFF000000),
      onBackground: Color(0xFFC5C5C5),
      surface: Color(0xFF141414),
      onSurface: Color(0xFFDDDDDD));

  static ThemeData get appLightTheme => ThemeData(
      fontFamily: GoogleFonts.lato().fontFamily,
      useMaterial3: true,
      colorScheme: lightColorScheme,

      // ELEVATED BUTTON
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: lightColorScheme.onPrimary,
          backgroundColor: lightColorScheme.primary,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        ),
      ),
      // APP BAR
      appBarTheme: AppBarTheme(
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        // backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30), // Adjust the radius as needed
          ),
        ),
        elevation: 0,

        toolbarHeight: 70,
        iconTheme: IconThemeData(
          color: lightColorScheme.outline,
          size: 24,
        ),
      ),

      // INPUT DECORATION
      inputDecorationTheme: InputDecorationTheme(
          floatingLabelBehavior: FloatingLabelBehavior.never,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          constraints: const BoxConstraints(
              // minHeight: 45,
              // maxHeight: 45,
              ),
          suffixIconColor: lightColorScheme.scrim,
          errorMaxLines: 2,
          errorStyle: TextStyle(
              color: lightColorScheme.error,
              fontSize: 14,
              fontWeight: FontWeight.w400),
          labelStyle: TextStyle(
              color: lightColorScheme.outlineVariant,
              fontSize: 14,
              fontWeight: FontWeight.w400),
          hintStyle: TextStyle(

              // height: 20,
              color: lightColorScheme.scrim,
              fontSize: 14,
              fontWeight: FontWeight.w400),

          // fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide:
                BorderSide(color: lightColorScheme.outlineVariant, width: .5),
          )),

      // TEXT THEMES
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w600,
          color: AppGrays.gray900,
        ),
        titleMedium: TextStyle(
          fontSize: 24,
          color: AppGrays.gray900,
        ),
        titleSmall: TextStyle(
          fontSize: 20,
          color: AppGrays.gray500,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppGrays.gray700,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppGrays.gray700,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: AppGrays.gray500,
        ),
      ));
  static ThemeData appDarkTheme = ThemeData(
    fontFamily: GoogleFonts.cairo().fontFamily,
    useMaterial3: true,
    colorScheme: darkColorScheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        backgroundColor: darkColorScheme.primary,
      ),
    ),
  );
}

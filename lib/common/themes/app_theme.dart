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

class AppShadow {
  /// Timid shadow
  static BoxShadow shadow0(BuildContext context) {
    return BoxShadow(
      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.20),
      offset: const Offset(0, 4),
      blurRadius: 18.2,
      spreadRadius: 0,
    );
  }

  /// Bright shadow
  static BoxShadow shadow1(BuildContext context) {
    return BoxShadow(
      color: Theme.of(context)
          .colorScheme
          .primary
          .withValues(alpha: 0.28), // The color of the glow
      offset: const Offset(0, 4),
      blurRadius: 16, // The intensity of the glow
      spreadRadius: 0,
    );
  }
}

class AppTheme {
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF7265E3),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFBCB5F7),
    onSecondary: Color(0xFF4E4E4E),
    error: Color(0xFFE54D52),
    onError: Color(0xFFFFFFFF),
    // background: Color(0xFFFDFCFF),

    // Background of the app
    surface: Color(0xFFFDFCFF),
    // surface: Colors.yellow,

    surfaceContainer: Color(0xFFFFFFFF),

    // an even deeper surface color than the surface to have an even flatter look
    // surfaceContainerLowest: Color(0xFFE54D52),

    // Color for cards and containers
    // surfaceContainerHighest: Color(0xFFE54D52),
    // surfaceContainerHigh: Color(0xFFE54D52),
    // surfaceContainerLow: Color(0xFFE54D52),
    // primaryContainer: Color(0xFFE54D52),
    // secondaryContainer: Color(0xFFE54D52),
    // surfaceContainerLowest: Color(0xFFE54D52),
    // surfaceContainerLowest: Color(0xFFFDFCFF),

    // TEXT – primary & secondary
    onSurface: AppGrays.gray900, // main text (titles, primary body)
    // onBackground: AppGrays.gray900,

    onSurfaceVariant: AppGrays.gray700, // secondary text, descriptions
    outline: AppGrays.gray500, // muted text, metadata, captions
    outlineVariant: AppGrays.gray300, // disabled text, hints, placeholders

    // Optional
    scrim: AppGrays.gray200, // very low emphasis / separators
  );
  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF5349B4),
    onPrimary: Color(0xFFEAEAEA),
    secondary: Color(0xFF28234F),
    onSecondary: Color(0xFFC5C5C5),
    error: Color(0xFFB82426),
    onError: Color(0xFFEAEAEA),
    surface: Color(0xFF000000),
    onSurface: Color(0xFFC5C5C5),

    surfaceContainer: Color(0xFF141414),

    onSurfaceVariant: AppGrays.gray700, // secondary text, descriptions
    outline: AppGrays.gray500, // muted text, metadata, captions
    outlineVariant: AppGrays.gray300, // disabled text, hints, placeholders

    // Optional
    scrim: AppGrays.gray200, // very low emphasis / separators
  );

  static ThemeData lightTheme() => _theme(_lightColorScheme, false);
  static ThemeData darkTheme() => _theme(_darkColorScheme, true);

  static ThemeData _theme(ColorScheme colorScheme, bool isDark) => ThemeData(
      fontFamily: GoogleFonts.cairo().fontFamily,
      useMaterial3: true,
      colorScheme: colorScheme,
      cardColor: colorScheme.surfaceContainer,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        shadowColor: Colors.transparent,
        elevation: 0,
      ),

      // ELEVATED BUTTON
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        ),
      ),
      // APP BAR
      appBarTheme: AppBarTheme(
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
            color: colorScheme.outline,
            size: 24,
          ),
          titleTextStyle: const TextStyle(
            fontSize: 24,
            height: 1.1,
            color: AppGrays.gray900,
            fontWeight: FontWeight.w700,
          )),

      // INPUT DECORATION
      inputDecorationTheme: InputDecorationTheme(
          floatingLabelBehavior: FloatingLabelBehavior.never,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          constraints: const BoxConstraints(
              // minHeight: 45,
              // maxHeight: 45,
              ),
          suffixIconColor: colorScheme.scrim,
          errorMaxLines: 2,
          errorStyle: TextStyle(
              height: 1.1,
              color: colorScheme.error,
              fontSize: 13,
              fontWeight: FontWeight.w400),
          labelStyle: TextStyle(
              height: 1.1,
              color: colorScheme.outlineVariant,
              fontSize: 13,
              fontWeight: FontWeight.w400),
          hintStyle: TextStyle(
              height: 1.1,

              // height: 20,
              color: colorScheme.scrim,
              fontSize: 13,
              fontWeight: FontWeight.w400),

          // fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide:
                BorderSide(color: colorScheme.outlineVariant, width: .5),
          )),

      // TEXT THEMES
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 30,
          height: 1.1,
          fontWeight: FontWeight.w600,
          color: AppGrays.gray900,
        ),
        titleMedium: TextStyle(
          fontSize: 24,
          height: 1.1,
          color: AppGrays.gray900,
        ),
        titleSmall: TextStyle(
          fontSize: 20,
          height: 1.1,
          color: AppGrays.gray500,
        ),
        bodyLarge: TextStyle(
          height: 1.1,
          fontSize: 16,
          color: AppGrays.gray700,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.1,
          color: AppGrays.gray700,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.1,
          color: AppGrays.gray500,
        ),
      ));
}

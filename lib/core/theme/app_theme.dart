import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFFFFFCF7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceRaised = Color(0xFFF8F0EA);
  static const paper = Color(0xFF3A3335);
  static const muted = Color(0xFF6F7470);
  static const accent = Color(0xFFEB5E55);
  static const raspberry = Color(0xFFD81E5B);
  static const ash = Color(0xFFC6D8D3);
  static const papayaWhip = Color(0xFFFDF0D5);
  static const line = Color(0xFFE6DDD7);

  static const darkBackground = Color(0xFF3A3335);
  static const darkSurface = Color(0xFF493F42);
  static const darkSurfaceRaised = Color(0xFF5A4A4F);
  static const darkPaper = papayaWhip;
  static const darkMuted = ash;
  static const darkLine = Color(0xFF6D5C60);

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      background,
      Color(0xFFFFF6F0),
      Color(0xFFFCEBEC),
      Color(0xFFF0F4F1),
    ],
  );

  static const darkBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      darkBackground,
      Color(0xFF4A303A),
      Color(0xFF72344A),
      Color(0xFF9C504C),
      Color(0xFF6A7771),
    ],
  );

  static ThemeData get light => _buildTheme(
        brightness: Brightness.light,
        background: background,
        surface: surface,
        surfaceRaised: surfaceRaised,
        primaryText: paper,
        secondaryText: muted,
        outline: line,
        onAccent: Colors.white,
      );

  static ThemeData get dark => _buildTheme(
        brightness: Brightness.dark,
        background: darkBackground,
        surface: darkSurface,
        surfaceRaised: darkSurfaceRaised,
        primaryText: darkPaper,
        secondaryText: darkMuted,
        outline: darkLine,
        onAccent: darkBackground,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceRaised,
    required Color primaryText,
    required Color secondaryText,
    required Color outline,
    required Color onAccent,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      surface: surface,
    ).copyWith(
      primary: accent,
      onPrimary: onAccent,
      secondary: raspberry,
      onSecondary: Colors.white,
      tertiary: ash,
      onSurface: primaryText,
      outline: outline,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'OpenSans',
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: outline,
      splashFactory: NoSplash.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: _textTheme(primaryText, secondaryText, onAccent),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: secondaryText),
        prefixIconColor: secondaryText,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: brightness == Brightness.light ? 1 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: outline,
        thumbColor: primaryText,
        overlayColor: accent.withValues(alpha: 0.12),
        trackHeight: 3,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: primaryText,
          highlightColor: accent.withValues(alpha: 0.12),
        ),
      ),
    );
  }

  static TextTheme _textTheme(
      Color primaryText, Color secondaryText, Color onAccent) {
    return TextTheme(
      displaySmall: TextStyle(
        fontFamily: 'FunnelDisplay',
        color: primaryText,
        fontSize: 42,
        height: 1.02,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.7,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'FunnelDisplay',
        color: primaryText,
        fontSize: 27,
        height: 1.12,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
      ),
      titleLarge: TextStyle(
        fontFamily: 'FunnelDisplay',
        color: primaryText,
        fontSize: 19,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontFamily: 'FunnelDisplay',
        color: primaryText,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: primaryText, fontSize: 16, height: 1.4),
      bodyMedium: TextStyle(color: secondaryText, fontSize: 14, height: 1.35),
      labelLarge: TextStyle(
        fontFamily: 'FunnelDisplay',
        color: onAccent,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: TextStyle(
        fontFamily: 'FunnelDisplay',
        color: secondaryText,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

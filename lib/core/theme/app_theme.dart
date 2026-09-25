import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF3A3335);
  static const surface = Color(0xFF493F42);
  static const surfaceRaised = Color(0xFF5A4A4F);
  static const paper = Color(0xFFFDF0D5);
  static const muted = Color(0xFFC6D8D3);
  static const accent = Color(0xFFEB5E55);
  static const raspberry = Color(0xFFD81E5B);
  static const line = Color(0xFF6D5C60);

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      background,
      Color(0xFF4A303A),
      Color(0xFF72344A),
      Color(0xFF9C504C),
      Color(0xFF6A7771),
    ],
  );

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      surface: surface,
    ).copyWith(
      primary: accent,
      onPrimary: background,
      secondary: raspberry,
      onSecondary: paper,
      tertiary: muted,
      onSurface: paper,
      outline: line,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: background,
      dividerColor: line,
      splashFactory: NoSplash.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: paper,
          fontSize: 38,
          height: 1.05,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
        ),
        headlineSmall: TextStyle(
          color: paper,
          fontSize: 25,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: paper,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: paper,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: paper,
          fontSize: 16,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          color: muted,
          fontSize: 14,
          height: 1.35,
        ),
        labelLarge: TextStyle(
          color: background,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
        labelMedium: TextStyle(
          color: muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: muted),
        prefixIconColor: muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: line,
        thumbColor: paper,
        overlayColor: accent.withOpacity(0.12),
        trackHeight: 3,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: paper,
          highlightColor: accent.withOpacity(0.12),
        ),
      ),
    );
  }
}

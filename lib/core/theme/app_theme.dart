import 'package:flutter/material.dart';

/// Brand palette and the `ThemeData` built from it.
///
/// The Clostel palette is fixed: coral is the action colour, raspberry the
/// secondary, and the warm paper/ash neutrals carry everything else. Funnel
/// Display sets display and heading type, Open Sans sets body and labels.
///
/// Light is the default appearance; dark is a full, equally coherent alternate.
/// Both expose the same semantic role names, so a widget can either read a role
/// from the ambient `ThemeData` (preferred, adapts automatically) or resolve an
/// [AppPalette] directly when it needs the raw brand colour.
class AppTheme {
  const AppTheme._();

  static const displayFont = 'FunnelDisplay';
  static const bodyFont = 'OpenSans';

  // --- Brand palette (shared by both brightnesses) ---------------------------

  static const background = Color(0xFFFFFCF7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceRaised = Color(0xFFF8F0EA);
  static const surfaceSunken = Color(0xFFF3EAE3);
  static const paper = Color(0xFF3A3335);
  static const muted = Color(0xFF6F7470);
  static const accent = Color(0xFFEB5E55);
  static const raspberry = Color(0xFFD81E5B);
  static const ash = Color(0xFFC6D8D3);
  static const papayaWhip = Color(0xFFFDF0D5);
  static const line = Color(0xFFE6DDD7);

  /// Deepened brand colour for filled surfaces.
  ///
  /// Coral at full strength only carries white text at roughly 3.3:1, which is
  /// under the bar for small text. Filled surfaces use this deeper coral;
  /// [accent] stays for text, icons and small marks, where the ratio holds.
  static const accentDeep = Color(0xFFC23A31);

  // --- Dark alternates --------------------------------------------------------

  static const darkBackground = Color(0xFF3A3335);
  static const darkSurface = Color(0xFF493F42);
  static const darkSurfaceRaised = Color(0xFF5A4A4F);
  static const darkSurfaceSunken = Color(0xFF2E282A);
  static const darkPaper = papayaWhip;
  static const darkMuted = Color(0xFFB4C4BE);
  static const darkLine = Color(0xFF6D5C60);
  static const darkAccent = Color(0xFFFF9C8F);
  static const darkRaspberry = Color(0xFFFF8FB6);
  static const darkAsh = Color(0xFF7E9C94);

  /// Paper-based text on a dark background sits around 11:1, far past what long
  /// passages need, which is why secondary text in dark mode reads as heavy as
  /// primary. These tints are the same ink pulled back to a readable contrast.
  static const darkPaperHigh = Color(0xFFFBF2EA);
  static const darkPaperMid = Color(0xFFE6DAD4);
  static const darkPaperLow = Color(0xFFC0B2AE);
  static const darkError = Color(0xFFFFB4AB);

  /// Warmer, less saturated outline so borders recede instead of glowing.
  static const darkLineSoft = Color(0xFF5A4B4F);

  // --- Gradients --------------------------------------------------------------

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

  /// Gradient for the ambient brightness. Preferred over the raw constants
  /// wherever a `BuildContext` is available.
  static LinearGradient backgroundGradientFor(BuildContext context) {
    return AppPalette.of(context).backgroundGradient;
  }

  // --- Theme resolution -------------------------------------------------------

  static ThemeData get light => _build(AppPalette.light);

  static ThemeData get dark => _build(AppPalette.dark);

  /// [ThemeData] for an explicit preference, e.g. a theme picker.
  static ThemeData forMode(ThemeMode mode, Brightness platformBrightness) {
    return switch (mode) {
      ThemeMode.light => light,
      ThemeMode.dark => dark,
      ThemeMode.system =>
        platformBrightness == Brightness.dark ? dark : light,
    };
  }

  /// Builds a complete theme from a palette so light and dark cannot drift
  /// apart: both run through this one path, differing only in [palette].
  static ThemeData _build(AppPalette palette) {
    final scheme = palette.isDark ? _darkScheme : _lightScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: scheme,
      fontFamily: bodyFont,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      dividerColor: palette.line,
      splashFactory: NoSplash.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: _textTheme(palette),
      appBarTheme: _appBarTheme(palette),
      cardTheme: _cardTheme(palette),
      dialogTheme: _dialogTheme(palette),
      bottomSheetTheme: _bottomSheetTheme(palette),
      drawerTheme: _drawerTheme(palette),
      listTileTheme: _listTileTheme(palette),
      navigationBarTheme: _navigationBarTheme(palette),
      navigationRailTheme: _navigationRailTheme(palette),
      tabBarTheme: _tabBarTheme(palette),
      chipTheme: _chipTheme(palette),
      inputDecorationTheme: _inputDecorationTheme(palette, scheme),
      filledButtonTheme: _filledButtonTheme(scheme),
      elevatedButtonTheme: _elevatedButtonTheme(palette),
      outlinedButtonTheme: _outlinedButtonTheme(palette),
      textButtonTheme: _textButtonTheme(scheme),
      iconButtonTheme: _iconButtonTheme(palette),
      floatingActionButtonTheme: _floatingActionButtonTheme(scheme),
      segmentedButtonTheme: _segmentedButtonTheme(palette),
      sliderTheme: _sliderTheme(palette),
      switchTheme: _switchTheme(palette),
      checkboxTheme: _checkboxTheme(scheme),
      radioTheme: _radioTheme(scheme),
      progressIndicatorTheme: _progressIndicatorTheme(palette),
      snackBarTheme: _snackBarTheme(scheme),
      tooltipTheme: _tooltipTheme(scheme),
      popupMenuTheme: _popupMenuTheme(palette),
      textSelectionTheme: _textSelectionTheme(palette),
    );
  }

  // --- Colour schemes ---------------------------------------------------------

  static ColorScheme get _lightScheme {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: accentDeep,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFFBE3DF),
      onPrimaryContainer: Color(0xFF6E1D17),
      secondary: raspberry,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFBE1EB),
      onSecondaryContainer: Color(0xFF5C0A2A),
      tertiary: Color(0xFF3F635B),
      onTertiary: Colors.white,
      tertiaryContainer: ash,
      onTertiaryContainer: Color(0xFF16241F),
      error: Color(0xFFAF2E23),
      onError: Colors.white,
      errorContainer: Color(0xFFFBDAD5),
      onErrorContainer: Color(0xFF410100),
      surface: surface,
      onSurface: paper,
      surfaceContainerLowest: surface,
      surfaceContainerLow: background,
      surfaceContainer: surfaceRaised,
      surfaceContainerHigh: surfaceSunken,
      surfaceContainerHighest: surfaceSunken,
      onSurfaceVariant: muted,
      outline: line,
      outlineVariant: Color(0xFFEFE7E1),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: paper,
      onInverseSurface: background,
      inversePrimary: darkAccent,
    );
  }

  static ColorScheme get _darkScheme {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: darkAccent,
      onPrimary: Color(0xFF5A1A12),
      primaryContainer: Color(0xFF7C2A22),
      onPrimaryContainer: Color(0xFFFFDAD3),
      secondary: darkRaspberry,
      onSecondary: Color(0xFF5A0A2C),
      secondaryContainer: Color(0xFF7B1240),
      onSecondaryContainer: Color(0xFFFFD9E5),
      tertiary: darkAsh,
      onTertiary: Color(0xFF11241E),
      tertiaryContainer: Color(0xFF2C423C),
      onTertiaryContainer: Color(0xFFCBE4DC),
      error: darkError,
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: darkSurface,
      onSurface: darkPaperHigh,
      surfaceContainerLowest: darkSurfaceSunken,
      surfaceContainerLow: darkBackground,
      surfaceContainer: darkSurface,
      surfaceContainerHigh: darkSurfaceRaised,
      surfaceContainerHighest: darkSurfaceRaised,
      onSurfaceVariant: darkPaperMid,
      outline: darkLine,
      outlineVariant: darkLineSoft,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: papayaWhip,
      onInverseSurface: Color(0xFF3A2E30),
      inversePrimary: accentDeep,
    );
  }

  // --- Typography -------------------------------------------------------------

  /// Funnel Display carries display, headline and title slots; Open Sans carries
  /// body and label slots, on a shared scale with matching line heights so the
  /// two families sit on the same rhythm.
  static TextTheme _textTheme(AppPalette palette) {
    return TextTheme(
      displayLarge:
          _display(72, FontWeight.w700, -2.8, 1.02, palette.textPrimary),
      displayMedium:
          _display(58, FontWeight.w700, -2.2, 1.03, palette.textPrimary),
      displaySmall:
          _display(42, FontWeight.w700, -1.7, 1.04, palette.textPrimary),
      headlineLarge:
          _display(34, FontWeight.w600, -1.0, 1.10, palette.textPrimary),
      headlineMedium:
          _display(30, FontWeight.w600, -0.8, 1.12, palette.textPrimary),
      headlineSmall:
          _display(27, FontWeight.w600, -0.6, 1.14, palette.textPrimary),
      titleLarge:
          _display(19, FontWeight.w600, -0.2, 1.25, palette.textPrimary),
      titleMedium:
          _display(16, FontWeight.w600, -0.1, 1.30, palette.textPrimary),
      titleSmall: _display(14, FontWeight.w600, 0, 1.35, palette.textPrimary),
      bodyLarge: _body(16, FontWeight.w400, 0.1, 1.45, palette.textPrimary),
      bodyMedium: _body(14, FontWeight.w400, 0.1, 1.45, palette.textSecondary),
      bodySmall: _body(12, FontWeight.w400, 0.2, 1.40, palette.textTertiary),
      labelLarge: _label(14, FontWeight.w600, 0.3, palette.textPrimary),
      labelMedium: _label(12, FontWeight.w600, 0.3, palette.textSecondary),
      labelSmall: _label(11, FontWeight.w600, 0.4, palette.textTertiary),
    );
  }

  static TextStyle _display(
    double size,
    FontWeight weight,
    double spacing,
    double height,
    Color color,
  ) {
    return TextStyle(
      fontFamily: displayFont,
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
    );
  }

  static TextStyle _body(
    double size,
    FontWeight weight,
    double spacing,
    double height,
    Color color,
  ) {
    return TextStyle(
      fontFamily: bodyFont,
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
    );
  }

  static TextStyle _label(
    double size,
    FontWeight weight,
    double spacing,
    Color color,
  ) {
    return TextStyle(
      fontFamily: bodyFont,
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: 1.2,
      letterSpacing: spacing,
    );
  }

  // --- Component themes -------------------------------------------------------

  static AppBarTheme _appBarTheme(AppPalette palette) {
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: palette.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle:
          _display(21, FontWeight.w600, -0.4, 1.2, palette.textPrimary),
    );
  }

  static CardThemeData _cardTheme(AppPalette palette) {
    return CardThemeData(
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: palette.isDark ? 0 : 1,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.line),
      ),
    );
  }

  static DialogThemeData _dialogTheme(AppPalette palette) {
    return DialogThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titleTextStyle:
          _display(21, FontWeight.w600, -0.4, 1.25, palette.textPrimary),
      contentTextStyle:
          _body(15, FontWeight.w400, 0.1, 1.45, palette.textSecondary),
    );
  }

  static BottomSheetThemeData _bottomSheetTheme(AppPalette palette) {
    return BottomSheetThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: palette.isDark ? Colors.black54 : Colors.black26,
      elevation: 6,
      modalElevation: 8,
      showDragHandle: true,
      dragHandleColor: palette.line,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
    );
  }

  static DrawerThemeData _drawerTheme(AppPalette palette) {
    return DrawerThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
    );
  }

  static ListTileThemeData _listTileTheme(AppPalette palette) {
    return ListTileThemeData(
      iconColor: palette.textSecondary,
      textColor: palette.textPrimary,
      titleTextStyle:
          _display(16, FontWeight.w600, -0.1, 1.3, palette.textPrimary),
      subtitleTextStyle:
          _body(13, FontWeight.w400, 0.1, 1.4, palette.textSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  static NavigationBarThemeData _navigationBarTheme(AppPalette palette) {
    return NavigationBarThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: palette.accent.withValues(alpha: 0.16),
      elevation: 0,
      height: 66,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 22,
          color: states.contains(WidgetState.selected)
              ? palette.actionFill
              : palette.textSecondary,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => _label(
          12,
          states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w600,
          0.3,
          states.contains(WidgetState.selected)
              ? palette.textPrimary
              : palette.textSecondary,
        ),
      ),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  static NavigationRailThemeData _navigationRailTheme(AppPalette palette) {
    return NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: palette.accent.withValues(alpha: 0.16),
      elevation: 0,
      useIndicator: true,
      selectedIconTheme: IconThemeData(color: palette.actionFill, size: 22),
      unselectedIconTheme:
          IconThemeData(color: palette.textSecondary, size: 22),
      selectedLabelTextStyle:
          _label(12, FontWeight.w700, 0.3, palette.textPrimary),
      unselectedLabelTextStyle:
          _label(12, FontWeight.w600, 0.3, palette.textSecondary),
    );
  }

  static TabBarThemeData _tabBarTheme(AppPalette palette) {
    return TabBarThemeData(
      labelColor: palette.textPrimary,
      unselectedLabelColor: palette.textSecondary,
      indicatorColor: palette.accent,
      indicatorSize: TabBarIndicatorSize.label,
      indicatorWeight: 3,
      dividerColor: Colors.transparent,
      labelStyle: _label(14, FontWeight.w700, 0.2, palette.textPrimary),
      unselectedLabelStyle:
          _label(14, FontWeight.w600, 0.2, palette.textSecondary),
      overlayColor:
          WidgetStatePropertyAll(palette.accent.withValues(alpha: 0.1)),
    );
  }

  static ChipThemeData _chipTheme(AppPalette palette) {
    return ChipThemeData(
      backgroundColor: palette.surfaceRaised,
      selectedColor: palette.accent.withValues(alpha: 0.18),
      disabledColor: palette.surfaceRaised.withValues(alpha: 0.5),
      side: BorderSide(color: palette.line),
      labelStyle: _label(12, FontWeight.w600, 0.3, palette.textSecondary),
      secondaryLabelStyle:
          _label(12, FontWeight.w600, 0.3, palette.textPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCheckmark: false,
    );
  }

  static InputDecorationTheme _inputDecorationTheme(
    AppPalette palette,
    ColorScheme scheme,
  ) {
    OutlineInputBorder outline(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      hintStyle: TextStyle(color: palette.textSecondary),
      labelStyle: _body(14, FontWeight.w400, 0.1, 1.2, palette.textSecondary),
      floatingLabelStyle:
          _body(14, FontWeight.w600, 0.1, 1.2, palette.textPrimary),
      helperStyle: _body(12, FontWeight.w400, 0.2, 1.3, palette.textTertiary),
      errorStyle: _body(12, FontWeight.w400, 0.2, 1.3, scheme.error),
      prefixIconColor: palette.textSecondary,
      suffixIconColor: palette.textSecondary,
      // Geometry unchanged from the original theme: the search field and
      // settings inputs already sit in fixed-height rows.
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      border: outline(palette.line),
      enabledBorder: outline(palette.line),
      focusedBorder: outline(palette.accent, 1.5),
      errorBorder: outline(scheme.error),
      focusedErrorBorder: outline(scheme.error, 1.5),
      disabledBorder: outline(palette.line.withValues(alpha: 0.6)),
    );
  }

  static FilledButtonThemeData _filledButtonTheme(ColorScheme scheme) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: _label(14, FontWeight.w700, 0.3, scheme.onPrimary),
        elevation: 0,
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(AppPalette palette) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        backgroundColor: palette.surfaceRaised,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: palette.line),
        ),
        textStyle: _label(14, FontWeight.w700, 0.3, palette.textPrimary),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(AppPalette palette) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        foregroundColor: palette.textPrimary,
        side: BorderSide(color: palette.line, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: _label(14, FontWeight.w700, 0.3, palette.textPrimary),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme(ColorScheme scheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        foregroundColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: _label(14, FontWeight.w700, 0.3, scheme.primary),
      ),
    );
  }

  static IconButtonThemeData _iconButtonTheme(AppPalette palette) {
    return IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: palette.textPrimary,
        highlightColor: palette.accent.withValues(alpha: 0.12),
        hoverColor: palette.accent.withValues(alpha: 0.08),
        splashRadius: 22,
      ),
    );
  }

  static FloatingActionButtonThemeData _floatingActionButtonTheme(
    ColorScheme scheme,
  ) {
    return FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      focusElevation: 3,
      hoverElevation: 3,
      highlightElevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }

  static SegmentedButtonThemeData _segmentedButtonTheme(AppPalette palette) {
    return SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.accent.withValues(alpha: 0.16)
              : palette.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.actionFill
              : palette.textSecondary,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: palette.line)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        textStyle: WidgetStatePropertyAll(
          _label(13, FontWeight.w700, 0.2, palette.textPrimary),
        ),
      ),
    );
  }

  static SliderThemeData _sliderTheme(AppPalette palette) {
    return SliderThemeData(
      activeTrackColor: palette.accent,
      inactiveTrackColor: palette.line,
      thumbColor: palette.textPrimary,
      overlayColor: palette.accent.withValues(alpha: 0.12),
      trackHeight: 3,
    );
  }

  static SwitchThemeData _switchTheme(AppPalette palette) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : palette.line,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.actionFill
            : palette.line.withValues(alpha: 0.5),
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }

  static CheckboxThemeData _checkboxTheme(ColorScheme scheme) {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primary
            : null,
      ),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      side: BorderSide(color: scheme.primary, width: 1.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }

  static RadioThemeData _radioTheme(ColorScheme scheme) {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primary
            : null,
      ),
    );
  }

  static ProgressIndicatorThemeData _progressIndicatorTheme(
    AppPalette palette,
  ) {
    return ProgressIndicatorThemeData(
      color: palette.accent,
      linearTrackColor: palette.line,
      circularTrackColor: palette.line,
      linearMinHeight: 4,
    );
  }

  static SnackBarThemeData _snackBarTheme(ColorScheme scheme) {
    return SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle:
          _body(14, FontWeight.w400, 0.1, 1.4, scheme.onInverseSurface),
      actionTextColor: scheme.inversePrimary,
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  static TooltipThemeData _tooltipTheme(ColorScheme scheme) {
    return TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      margin: const EdgeInsets.all(8),
      textStyle: _label(12, FontWeight.w500, 0.1, scheme.onInverseSurface),
      decoration: BoxDecoration(
        color: scheme.inverseSurface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  static PopupMenuThemeData _popupMenuTheme(AppPalette palette) {
    return PopupMenuThemeData(
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      textStyle: _body(14, FontWeight.w400, 0.1, 1.4, palette.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: palette.line),
      ),
    );
  }

  static TextSelectionThemeData _textSelectionTheme(AppPalette palette) {
    return TextSelectionThemeData(
      cursorColor: palette.accent,
      selectionColor: palette.accent.withValues(alpha: 0.28),
      selectionHandleColor: palette.accent,
    );
  }
}

/// Brightness-aware view of the Clostel palette.
///
/// The legacy `AppTheme.<colour>` constants remain the light brand palette and
/// are still referenced directly by the shell. New code should resolve the
/// palette from the context so the same widget reads correctly in both
/// brightnesses:
///
/// ```dart
/// final palette = AppPalette.of(context);
/// DecoratedBox(decoration: BoxDecoration(gradient: palette.backgroundGradient));
/// ```
@immutable
class AppPalette {
  const AppPalette._({
    required this.brightness,
    required this.background,
    required this.backgroundGradient,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.actionFill,
    required this.secondary,
    required this.tertiary,
    required this.line,
  });

  /// Palette for [context]'s ambient brightness.
  factory AppPalette.of(BuildContext context) {
    return forBrightness(Theme.of(context).brightness);
  }

  /// Palette for an explicit [brightness], e.g. for painting outside the tree.
  factory AppPalette.forBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }

  static const AppPalette light = AppPalette._(
    brightness: Brightness.light,
    background: AppTheme.background,
    backgroundGradient: AppTheme.backgroundGradient,
    surface: AppTheme.surface,
    surfaceRaised: AppTheme.surfaceRaised,
    surfaceSunken: AppTheme.surfaceSunken,
    textPrimary: AppTheme.paper,
    textSecondary: AppTheme.muted,
    textTertiary: Color(0xFF8A8F8A),
    accent: AppTheme.accent,
    actionFill: AppTheme.accentDeep,
    secondary: AppTheme.raspberry,
    tertiary: Color(0xFF3F635B),
    line: AppTheme.line,
  );

  static const AppPalette dark = AppPalette._(
    brightness: Brightness.dark,
    background: AppTheme.darkBackground,
    backgroundGradient: AppTheme.darkBackgroundGradient,
    surface: AppTheme.darkSurface,
    surfaceRaised: AppTheme.darkSurfaceRaised,
    surfaceSunken: AppTheme.darkSurfaceSunken,
    textPrimary: AppTheme.darkPaperHigh,
    textSecondary: AppTheme.darkPaperMid,
    textTertiary: AppTheme.darkPaperLow,
    accent: AppTheme.darkAccent,
    actionFill: AppTheme.darkAccent,
    secondary: AppTheme.darkRaspberry,
    tertiary: AppTheme.darkAsh,
    line: AppTheme.darkLineSoft,
  );

  final Brightness brightness;
  final Color background;
  final LinearGradient backgroundGradient;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// Brand coral, tuned per brightness. Use for text, icons and small marks.
  final Color accent;

  /// Deeper or lighter variant of [accent] that carries a filled surface.
  final Color actionFill;
  final Color secondary;
  final Color tertiary;
  final Color line;

  bool get isDark => brightness == Brightness.dark;
}

/// Whether [context] currently renders with dark surfaces.
bool isDark(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

/// App-wide theme selection.
///
/// Defaults to [ThemeMode.system] so the app follows the platform appearance
/// out of the box, while staying the single seam a settings surface can drive
/// later. It is an in-memory [ValueNotifier]: persistence is left to the caller
/// (restore a saved mode through [ThemeModeController.restore] at startup)
/// rather than pulling a storage dependency into the theme layer.
///
/// ```dart
/// final themes = ThemeModeController();      // follows the system
/// themes.restore(savedMode);                 // optional
/// ClostelApp(controller: ..., themeController: themes);
/// ```
class ThemeModeController extends ValueNotifier<ThemeMode> {
  ThemeModeController({ThemeMode mode = ThemeMode.system}) : super(mode);

  /// The default controller: follows the system brightness.
  factory ThemeModeController.system() => ThemeModeController();

  /// Applies a stored preference, ignoring anything that is not a valid mode.
  void restore(Object? stored) {
    if (stored is ThemeMode) {
      setMode(stored);
    }
  }

  void setMode(ThemeMode mode) {
    if (mode != value) {
      value = mode;
    }
  }

  /// True when [platformBrightness] resolves to the dark theme.
  bool isDarkFor(Brightness platformBrightness) {
    return switch (value) {
      ThemeMode.light => false,
      ThemeMode.dark => true,
      ThemeMode.system => platformBrightness == Brightness.dark,
    };
  }

  /// Flips an explicit preference, resolving [ThemeMode.system] against
  /// [platformBrightness] first so a toggle from "system" is predictable.
  void toggle(Brightness platformBrightness) {
    setMode(isDarkFor(platformBrightness) ? ThemeMode.light : ThemeMode.dark);
  }

  /// Label for a settings control describing the current preference.
  String labelFor(Brightness platformBrightness) {
    return switch (value) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system =>
        isDarkFor(platformBrightness) ? 'System (dark)' : 'System (light)',
    };
  }
}

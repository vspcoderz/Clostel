import 'package:flutter/material.dart';

import 'core/services/discord_presence.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_shell.dart';
import 'features/player/player_controller.dart';

class ClostelApp extends StatefulWidget {
  const ClostelApp({
    required this.controller,
    required this.discordPresence,
    this.themeController,
    super.key,
  });

  final PlayerController controller;
  final DiscordPresenceService discordPresence;

  /// Theme selection seam. Left null, the app follows the system appearance.
  /// Pass a shared instance to let a settings surface change the mode at
  /// runtime, and to restore a persisted preference at startup.
  final ThemeModeController? themeController;

  @override
  State<ClostelApp> createState() => _ClostelAppState();
}

class _ClostelAppState extends State<ClostelApp> {
  late final ThemeModeController _themes;

  @override
  void initState() {
    super.initState();
    // Owned here only when the caller does not supply one, so an injected
    // controller is never disposed by the app.
    _themes = widget.themeController ?? ThemeModeController();
  }

  @override
  void dispose() {
    if (widget.themeController == null) {
      _themes.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themes,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Clostel',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: HomeShell(
            controller: widget.controller,
            discordPresence: widget.discordPresence,
            themeController: _themes,
          ),
        );
      },
    );
  }
}

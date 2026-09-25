import 'package:flutter/material.dart';

import 'core/services/discord_presence.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_shell.dart';
import 'features/player/player_controller.dart';

class ClostelApp extends StatelessWidget {
  const ClostelApp({
    required this.controller,
    required this.discordPresence,
    super.key,
  });

  final PlayerController controller;
  final DiscordPresenceService discordPresence;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clostel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      home: HomeShell(controller: controller, discordPresence: discordPresence),
    );
  }
}

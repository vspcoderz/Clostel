import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_shell.dart';
import 'features/player/player_controller.dart';

class ClostelApp extends StatelessWidget {
  const ClostelApp({required this.controller, super.key});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clostel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: HomeShell(controller: controller),
    );
  }
}

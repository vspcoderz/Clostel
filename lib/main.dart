import 'package:flutter/material.dart';

import 'app.dart';
import 'core/data/demo_catalog.dart';
import 'core/services/playback_service.dart';
import 'features/player/player_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = PlayerController(
    catalog: DemoMusicCatalog(),
    playback: JustAudioPlaybackService(),
  );
  runApp(ClostelApp(controller: controller));
}

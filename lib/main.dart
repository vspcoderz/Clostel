import 'package:flutter/material.dart';

import 'app.dart';
import 'core/data/deezer_catalog.dart';
import 'core/data/demo_catalog.dart';
import 'core/data/resilient_catalog.dart';
import 'core/services/discord_presence.dart';
import 'core/services/playback_service.dart';
import 'features/player/player_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final discordPresence = DiscordPresenceService(
    applicationId: const String.fromEnvironment('DISCORD_APPLICATION_ID'),
  );
  try {
    await discordPresence.initialize();
  } catch (_) {
    // Discord presence is optional; the music app still launches without it.
  }

  final controller = PlayerController(
    catalog: ResilientMusicCatalog(
      primary: DeezerMusicCatalog(),
      fallback: DemoMusicCatalog(),
    ),
    playback: JustAudioPlaybackService(),
  );
  runApp(ClostelApp(controller: controller, discordPresence: discordPresence));
}

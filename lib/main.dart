import 'package:flutter/material.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'app.dart';
import 'core/data/deezer_catalog.dart';
import 'core/data/demo_catalog.dart';
import 'core/data/jamendo_catalog.dart';
import 'core/data/music_catalog_chain.dart';
import 'core/data/resilient_catalog.dart';
import 'core/services/discord_presence.dart';
import 'core/services/local_music_service.dart';
import 'core/services/playback_service.dart';
import 'features/player/player_controller.dart';

const _defaultDiscordApplicationId = '1385145000718897152';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  JustAudioMediaKit.ensureInitialized(linux: true, windows: true);

  final discordPresence = DiscordPresenceService(
    applicationId: const String.fromEnvironment(
      'DISCORD_APPLICATION_ID',
      defaultValue: _defaultDiscordApplicationId,
    ),
  );
  try {
    await discordPresence.initialize();
  } catch (_) {
    // Discord presence is optional; the music app still launches without it.
  }

  final controller = PlayerController(
    catalog: ResilientMusicCatalog(
      primary: MusicCatalogChain(
        sources: [
          const JamendoMusicCatalog(
            clientId: String.fromEnvironment('JAMENDO_CLIENT_ID'),
          ),
          DeezerMusicCatalog(),
        ],
      ),
      fallback: DemoMusicCatalog(),
    ),
    playback: JustAudioPlaybackService(),
    localMusic: const LocalMusicService(),
  );
  runApp(ClostelApp(controller: controller, discordPresence: discordPresence));
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'app.dart';
import 'core/data/audius_catalog.dart';
import 'core/data/bhariya_music_catalog.dart';
import 'core/data/ccmixter_catalog.dart';
import 'core/data/deezer_catalog.dart';
import 'core/data/demo_catalog.dart';
import 'core/data/internet_archive_catalog.dart';
import 'core/data/itunes_catalog.dart';
import 'core/data/jamendo_catalog.dart';
import 'core/data/music_catalog_chain.dart';
import 'core/data/openverse_catalog.dart';
import 'core/data/resilient_catalog.dart';
import 'core/data/yt_dlp_catalog.dart';
import 'core/services/discord_presence.dart';
import 'core/services/local_music_service.dart';
import 'core/services/music_catalog.dart';
import 'core/services/playback_service.dart';
import 'core/services/track_file_resolver.dart';
import 'core/services/yt_dlp_audio_resolver.dart';
import 'core/services/yt_dlp_runner.dart';
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
    startEnabled: const String.fromEnvironment(
          'DISCORD_PRESENCE_ENABLED',
        ).trim().toLowerCase() ==
        'true',
  );
  final ytDlpExecutable = await _resolveYtDlpExecutable();
  final fileResolvers = <TrackFileResolver>[];
  final catalogSources = <MusicCatalog>[
    const JamendoMusicCatalog(
      clientId: String.fromEnvironment('JAMENDO_CLIENT_ID'),
    ),
    const AudiusMusicCatalog(
      apiKey: String.fromEnvironment('AUDIUS_API_KEY'),
    ),
    const CcMixterMusicCatalog(),
    const OpenverseMusicCatalog(),
    const InternetArchiveMusicCatalog(),
    const DeezerMusicCatalog(),
    const ITunesMusicCatalog(),
  ];
  final bhariyaMusicCatalog = BhariyaMusicCatalog(
    apiBaseUrl: const String.fromEnvironment(
      'BHARIYA_MUSIC_API_BASE_URL',
    ),
    audioEnabled: const String.fromEnvironment(
          'BHARIYA_MUSIC_AUDIO_ENABLED',
        ).trim().toLowerCase() ==
        'true',
  );
  if (bhariyaMusicCatalog.isConfigured) {
    catalogSources.add(bhariyaMusicCatalog);
  }
  if (ytDlpExecutable != null) {
    final searchRunner = ProcessYtDlpRunner(
      executable: ytDlpExecutable,
      timeout: const Duration(seconds: 45),
    );
    final downloadRunner = ProcessYtDlpRunner(executable: ytDlpExecutable);
    catalogSources.insert(0, YtDlpMusicCatalog(runner: searchRunner));
    fileResolvers.add(YtDlpAudioResolver(runner: downloadRunner));
  }
  final controller = PlayerController(
    catalog: ResilientMusicCatalog(
      primary: MusicCatalogChain(
        sources: catalogSources,
        maxResults: 80,
      ),
      fallback: DemoMusicCatalog(),
    ),
    playback: JustAudioPlaybackService(fileResolvers: fileResolvers),
    localMusic: const LocalMusicService(),
  );
  runApp(ClostelApp(controller: controller, discordPresence: discordPresence));
  unawaited(discordPresence.initialize());
}

Future<String?> _resolveYtDlpExecutable() async {
  if (const String.fromEnvironment('YT_DLP_DISABLED').trim().toLowerCase() ==
      'true') {
    return null;
  }
  if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
    return null;
  }

  final configuredPath = const String.fromEnvironment('YT_DLP_PATH').trim();
  final candidates = <String>[
    if (configuredPath.isNotEmpty) configuredPath,
    if (Platform.isWindows) ...['yt-dlp.exe', 'yt-dlp'],
    if (!Platform.isWindows) 'yt-dlp',
  ];

  for (final candidate in candidates) {
    try {
      final result = await Process.run(
        candidate,
        ['--version'],
        runInShell: false,
      ).timeout(const Duration(seconds: 5));
      if (result.exitCode == 0) {
        return candidate;
      }
    } on Object {
      // Try the next platform-specific executable name.
    }
  }
  return null;
}

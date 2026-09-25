import 'dart:async';

import 'package:discord_rich_presence/discord_rich_presence.dart';
import 'package:flutter/foundation.dart';

import '../models/track.dart';

class DiscordPresenceService {
  DiscordPresenceService({required this.applicationId});

  final String? applicationId;
  Client? _client;
  Track? _lastTrack;
  bool _lastIsPlaying = false;
  bool _userEnabled = true;

  bool get isConfigured {
    if (applicationId == null || applicationId!.trim().isEmpty) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.windows ||
      TargetPlatform.macOS =>
        true,
      _ => false,
    };
  }

  bool get isEnabled => isConfigured && _userEnabled;

  Future<void> initialize() async {
    if (!isConfigured) {
      return;
    }

    final client = Client(clientId: applicationId!);
    await client.connect();
    _client = client;
  }

  Future<void> setEnabled(bool enabled) async {
    _userEnabled = enabled;
    final client = _client;
    if (client == null || !isConfigured) {
      return;
    }

    if (!enabled) {
      await client.setActivity(
        Activity(
          name: 'Clostel',
          type: ActivityType.listening,
          state: 'Rich Presence off',
        ),
      );
      return;
    }

    await _setPresence(client, track: _lastTrack, isPlaying: _lastIsPlaying);
  }

  void update({required Track? track, required bool isPlaying}) {
    _lastTrack = track;
    _lastIsPlaying = isPlaying;

    final client = _client;
    if (!isEnabled || client == null) {
      return;
    }

    unawaited(_setPresence(client, track: track, isPlaying: isPlaying));
  }

  Future<void> _setPresence(
    Client client, {
    required Track? track,
    required bool isPlaying,
  }) async {
    final activity = track == null
        ? Activity(
            name: 'Clostel',
            type: ActivityType.listening,
            state: 'Ready to listen',
          )
        : Activity(
            name: 'Clostel',
            type: ActivityType.listening,
            details: track.title,
            state:
                '${isPlaying ? 'Listening now' : 'Paused'}  •  ${track.artist}',
            assets: ActivityAssets(
              largeText: 'Clostel',
              smallText: track.album,
            ),
            timestamps: ActivityTimestamps(start: DateTime.now()),
          );

    await client.setActivity(activity);
  }

  void dispose() {
    final client = _client;
    _client = null;
    _lastTrack = null;
    if (client != null) {
      unawaited(client.disconnect());
    }
  }
}

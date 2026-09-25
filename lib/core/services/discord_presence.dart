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

  bool get isEnabled => isConfigured && _userEnabled && _client != null;

  Future<void> initialize() async {
    if (!isConfigured || _userEnabled == false) {
      return;
    }
    await _connect();
  }

  Future<void> setEnabled(bool enabled) async {
    _userEnabled = enabled;
    if (!isConfigured) {
      return;
    }

    if (!enabled) {
      final client = _client;
      if (client == null) {
        return;
      }
      await _setPresence(
        client,
        track: null,
        isPlaying: false,
        disabled: true,
      );
      return;
    }

    final client = await _connect();
    if (client == null) {
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

  Future<Client?> _connect() async {
    if (_client != null) {
      return _client;
    }
    if (!isConfigured) {
      return null;
    }

    try {
      final client = Client(clientId: applicationId!);
      await client.connect();
      _client = client;
      return client;
    } catch (_) {
      _userEnabled = false;
      return null;
    }
  }

  Future<void> _setPresence(
    Client client, {
    required Track? track,
    required bool isPlaying,
    bool disabled = false,
  }) async {
    try {
      final activity = disabled
          ? Activity(
              name: 'Clostel',
              type: ActivityType.listening,
              state: 'Rich Presence off',
            )
          : track == null
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
    } catch (_) {
      _client = null;
      _userEnabled = false;
    }
  }

  void dispose() {
    final client = _client;
    _client = null;
    _lastTrack = null;
    if (client != null) {
      unawaited(_disconnect(client));
    }
  }

  Future<void> _disconnect(Client client) async {
    try {
      await client.disconnect();
    } catch (_) {
      // Discord may already have closed its IPC socket.
    }
  }
}

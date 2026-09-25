import 'dart:async';

import 'package:discord_rich_presence/discord_rich_presence.dart';
import 'package:flutter/foundation.dart';

import '../models/track.dart';

enum DiscordPresenceConnectionState {
  disabled,
  connecting,
  connected,
  unavailable,
}

typedef DiscordPresenceClientFactory = Client Function(String applicationId);

class DiscordPresenceService extends ChangeNotifier {
  DiscordPresenceService({
    required this.applicationId,
    bool startEnabled = false,
    DiscordPresenceClientFactory? clientFactory,
    Duration connectionTimeout = const Duration(seconds: 5),
    Duration reconnectDelay = const Duration(seconds: 8),
  })  : _userEnabled = startEnabled,
        _clientFactory =
            clientFactory ?? ((clientId) => Client(clientId: clientId)),
        _connectionTimeout = connectionTimeout,
        _reconnectDelay = reconnectDelay {
    _connectionState = !isConfigured
        ? DiscordPresenceConnectionState.unavailable
        : startEnabled
            ? DiscordPresenceConnectionState.connecting
            : DiscordPresenceConnectionState.disabled;
  }

  final String? applicationId;
  final DiscordPresenceClientFactory _clientFactory;
  final Duration _connectionTimeout;
  final Duration _reconnectDelay;

  Client? _client;
  Client? _connectingClient;
  Future<Client?>? _connectionAttempt;
  Track? _lastTrack;
  Timer? _reconnectTimer;
  bool _lastIsPlaying = false;
  bool _userEnabled;
  bool _disposed = false;
  DiscordPresenceConnectionState _connectionState =
      DiscordPresenceConnectionState.disabled;

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

  /// Whether the user's intent is enabled, even when Discord is unavailable.
  bool get userEnabled => _userEnabled;

  /// Whether an RPC socket is currently connected.
  bool get isEnabled =>
      _connectionState == DiscordPresenceConnectionState.connected;

  /// A listenable transport state intended for settings and status UI.
  DiscordPresenceConnectionState get connectionState => _connectionState;

  Future<void> initialize() async {
    if (!isConfigured || !_userEnabled || _disposed) {
      return;
    }
    await _connectAndPublish();
  }

  Future<void> setEnabled(bool enabled) async {
    if (_disposed) {
      return;
    }

    _userEnabled = enabled;
    if (!enabled) {
      _cancelReconnect();
      final client = _client;
      _client = null;
      _setConnectionState(DiscordPresenceConnectionState.disabled);
      if (client != null) {
        await _disconnect(client);
      }
      return;
    }

    if (!isConfigured) {
      _setConnectionState(DiscordPresenceConnectionState.unavailable);
      return;
    }

    await _connectAndPublish();
  }

  void update({required Track? track, required bool isPlaying}) {
    _lastTrack = track;
    _lastIsPlaying = isPlaying;

    final client = _client;
    if (!isConfigured || !_userEnabled || _disposed) {
      return;
    }
    if (client == null) {
      _scheduleReconnect();
      return;
    }

    unawaited(
      _runSafely(
        () => _setPresence(
          client,
          track: track,
          isPlaying: isPlaying,
        ),
      ),
    );
  }

  Future<void> _connectAndPublish() async {
    final client = await _connect();
    if (client == null) {
      _scheduleReconnect();
      return;
    }
    if (!_userEnabled || _disposed || !identical(_client, client)) {
      return;
    }

    await _setPresence(
      client,
      track: _lastTrack,
      isPlaying: _lastIsPlaying,
    );
  }

  Future<Client?> _connect() async {
    if (_disposed || !_userEnabled || !isConfigured) {
      return null;
    }

    final client = _client;
    if (client != null) {
      _setConnectionState(DiscordPresenceConnectionState.connected);
      return client;
    }

    final activeAttempt = _connectionAttempt;
    if (activeAttempt != null) {
      return activeAttempt;
    }

    _setConnectionState(DiscordPresenceConnectionState.connecting);
    final attempt = _openConnection();
    _connectionAttempt = attempt;
    try {
      return await attempt;
    } finally {
      if (identical(_connectionAttempt, attempt)) {
        _connectionAttempt = null;
      }
    }
  }

  Future<Client?> _openConnection() async {
    Client? client;
    Client? connected;
    var transportFailed = false;

    try {
      client = _clientFactory(applicationId!.trim());
      _connectingClient = client;

      try {
        await client!.connect().timeout(_connectionTimeout);
      } catch (_) {
        transportFailed = true;
        _handleTransportFailure(client!);
        return null;
      }
      connected = client;

      if (transportFailed || connected == null || _disposed || !_userEnabled) {
        return null;
      }

      _client = connected;
      _setConnectionState(DiscordPresenceConnectionState.connected);
      return connected;
    } catch (_) {
      if (client != null) {
        _handleTransportFailure(client);
      } else if (_userEnabled && !_disposed) {
        _setConnectionState(DiscordPresenceConnectionState.unavailable);
      }
      return null;
    } finally {
      if (identical(_connectingClient, client)) {
        _connectingClient = null;
      }
      if (client != null && !identical(_client, client)) {
        await _disconnect(client);
      }
      if (_userEnabled &&
          !_disposed &&
          _client == null &&
          _connectionState == DiscordPresenceConnectionState.connecting) {
        _setConnectionState(DiscordPresenceConnectionState.unavailable);
      }
      if (_userEnabled && !_disposed && _client == null) {
        _scheduleReconnect();
      }
    }
  }

  void _handleTransportFailure(Client client) {
    if (_disposed || !_userEnabled) {
      return;
    }

    final isCurrent = identical(_client, client);
    final isConnecting = identical(_connectingClient, client);
    if (!isCurrent && !isConnecting) {
      return;
    }

    if (isCurrent) {
      _client = null;
      unawaited(_runSafely(() => _disconnect(client)));
    }
    _setConnectionState(DiscordPresenceConnectionState.unavailable);
    _scheduleReconnect();
  }

  Future<void> _setPresence(
    Client client, {
    required Track? track,
    required bool isPlaying,
  }) async {
    try {
      final assets = track?.artworkUrl != null
          ? ActivityAssets.fromExternalLink(
              track!.artworkUrl!,
              text: track.album,
            )
          : ActivityAssets(
              largeText: 'Clostel',
              smallText: track?.album,
            );
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
              assets: assets,
              timestamps: ActivityTimestamps(start: DateTime.now()),
            );
      await client.setActivity(activity);
    } catch (_) {
      _handleTransportFailure(client);
    }
  }

  void _scheduleReconnect() {
    if (_disposed ||
        !_userEnabled ||
        !isConfigured ||
        _client != null ||
        _connectionAttempt != null ||
        _reconnectTimer != null) {
      return;
    }

    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectTimer = null;
      unawaited(_runSafely(_connectAndPublish));
    });
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> _runSafely(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (_) {
      // Discord presence must never surface transport errors to the music app.
    }
  }

  void _setConnectionState(DiscordPresenceConnectionState state) {
    if (_disposed || _connectionState == state) {
      return;
    }
    _connectionState = state;
    notifyListeners();
  }

  Future<void> _disconnect(Client client) async {
    try {
      await client.disconnect();
    } catch (_) {
      // Discord may already have closed its IPC socket.
    }
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _userEnabled = false;
    _cancelReconnect();
    final client = _client;
    _client = null;
    _lastTrack = null;
    _connectionState = DiscordPresenceConnectionState.disabled;
    if (client != null) {
      unawaited(_runSafely(() => _disconnect(client)));
    }
    super.dispose();
  }
}

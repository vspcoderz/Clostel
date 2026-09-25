import 'package:clostel/core/services/discord_presence.dart';
import 'package:discord_rich_presence/discord_rich_presence.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('stays opt-in until the user enables presence', () async {
    var clientsCreated = 0;
    final service = DiscordPresenceService(
      applicationId: 'test-application-id',
      clientFactory: (_) {
        clientsCreated++;
        return _FakeDiscordClient();
      },
      reconnectDelay: const Duration(days: 1),
    );
    addTearDown(service.dispose);

    await service.initialize();

    expect(clientsCreated, 0);
    expect(service.userEnabled, isFalse);
    expect(service.isEnabled, isFalse);
    expect(
      service.connectionState,
      DiscordPresenceConnectionState.disabled,
    );
  });

  test('disconnect and re-enable establish a fresh RPC connection', () async {
    final clients = <_FakeDiscordClient>[];
    final service = DiscordPresenceService(
      applicationId: 'test-application-id',
      clientFactory: (_) {
        final client = _FakeDiscordClient();
        clients.add(client);
        return client;
      },
      reconnectDelay: const Duration(days: 1),
    );
    addTearDown(service.dispose);

    await service.setEnabled(true);

    expect(clients, hasLength(1));
    expect(clients.single.connectCalls, 1);
    expect(clients.single.setActivityCalls, 1);
    expect(service.isEnabled, isTrue);
    expect(
      service.connectionState,
      DiscordPresenceConnectionState.connected,
    );

    await service.setEnabled(false);

    expect(clients.single.disconnectCalls, 1);
    expect(
      service.connectionState,
      DiscordPresenceConnectionState.disabled,
    );

    await service.setEnabled(true);

    expect(clients, hasLength(2));
    expect(clients.last.connectCalls, 1);
    expect(clients.last.setActivityCalls, 1);
    expect(
      service.connectionState,
      DiscordPresenceConnectionState.connected,
    );
  });

  test(
    'missing Discord IPC fails safely and exposes unavailable state',
    () async {
      final clients = <_FakeDiscordClient>[];
      final service = DiscordPresenceService(
        applicationId: 'test-application-id',
        clientFactory: (_) {
          final client = _FakeDiscordClient(
            connectError: StateError('Discord is not running'),
          );
          clients.add(client);
          return client;
        },
        reconnectDelay: const Duration(days: 1),
      );
      addTearDown(service.dispose);

      await expectLater(service.setEnabled(true), completes);

      expect(clients, hasLength(1));
      expect(clients.single.disconnectCalls, 1);
      expect(service.userEnabled, isTrue);
      expect(service.isEnabled, isFalse);
      expect(
        service.connectionState,
        DiscordPresenceConnectionState.unavailable,
      );
    },
  );

  test('captures activity errors without leaking them', () async {
    final client = _FakeDiscordClient(
      activityError: StateError('Discord closed the IPC socket'),
    );
    final service = DiscordPresenceService(
      applicationId: 'test-application-id',
      clientFactory: (_) => client,
      reconnectDelay: const Duration(days: 1),
    );
    addTearDown(service.dispose);

    await service.setEnabled(true);

    expect(
      service.connectionState,
      DiscordPresenceConnectionState.unavailable,
    );
    expect(service.isEnabled, isFalse);
  });
}

class _FakeDiscordClient extends Client {
  _FakeDiscordClient({
    this.connectError,
    this.activityError,
  }) : super(clientId: 'test-application-id');

  final Object? connectError;
  final Object? activityError;
  int connectCalls = 0;
  int disconnectCalls = 0;
  int setActivityCalls = 0;

  @override
  Future<void> connect() async {
    connectCalls++;
    if (connectError case final error?) {
      throw error;
    }
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
  }

  @override
  Future<void> setActivity(Activity activity) async {
    setActivityCalls++;
    if (activityError case final error?) {
      throw error;
    }
  }
}

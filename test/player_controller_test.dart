import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:clostel/core/data/demo_catalog.dart';
import 'package:clostel/core/models/track.dart';
import 'package:clostel/core/services/playback_service.dart';
import 'package:clostel/features/player/player_controller.dart';

void main() {
  test('playback controller loads a track and advances through the queue',
      () async {
    final playback = FakePlaybackService();
    final catalog = DemoMusicCatalog();
    final controller = PlayerController(catalog: catalog, playback: playback);
    addTearDown(controller.dispose);

    await controller.loadFeatured();
    await controller.playTrack(DemoMusicCatalog.tracks.first,
        queue: DemoMusicCatalog.tracks);
    await Future<void>.delayed(Duration.zero);

    expect(controller.currentTrack?.title, 'Night Transit');
    expect(controller.isPlaying, isTrue);
    expect(playback.loaded, [DemoMusicCatalog.tracks.first]);
    expect(controller.hasNext, isTrue);

    await controller.skipNext();
    await Future<void>.delayed(Duration.zero);

    expect(controller.currentTrack?.title, 'Amber Static');
    expect(playback.loaded,
        [DemoMusicCatalog.tracks.first, DemoMusicCatalog.tracks[1]]);
    expect(controller.isPlaying, isTrue);
  });

  test('exposes playback status through a UI-independent snapshot', () async {
    final playback = FakePlaybackService();
    final track = DemoMusicCatalog.tracks.first;
    final controller = PlayerController(
      catalog: DemoMusicCatalog(),
      playback: playback,
    );
    addTearDown(controller.dispose);

    expect(controller.status, PlaybackStatus.idle);
    expect(controller.snapshot.status, PlaybackStatus.idle);

    await controller.playTrack(track, queue: [track]);
    await Future<void>.delayed(Duration.zero);

    expect(controller.status, PlaybackStatus.playing);
    expect(controller.snapshot.status, PlaybackStatus.playing);
    expect(controller.snapshot.currentTrack, same(track));
    expect(controller.snapshot.queue, [track]);

    playback.status.add(PlaybackStatus.buffering);
    await Future<void>.delayed(Duration.zero);
    expect(controller.snapshot.status, PlaybackStatus.buffering);
    expect(controller.snapshot.isPlaying, isTrue);

    playback.status.add(PlaybackStatus.ended);
    playback.completed.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(controller.snapshot.status, PlaybackStatus.ended);

    await controller.togglePlayback();
    await Future<void>.delayed(Duration.zero);
    expect(controller.snapshot.status, PlaybackStatus.playing);
  });

  test('reports loading until a track source is ready', () async {
    final playback = FakePlaybackService();
    final loadGate = Completer<void>();
    playback.loadGate = loadGate;
    final track = DemoMusicCatalog.tracks.first;
    final controller = PlayerController(
      catalog: DemoMusicCatalog(),
      playback: playback,
    );
    addTearDown(controller.dispose);

    final playbackRequest = controller.playTrack(track, queue: [track]);
    expect(controller.status, PlaybackStatus.loading);

    loadGate.complete();
    await playbackRequest;
    await Future<void>.delayed(Duration.zero);
    expect(controller.status, PlaybackStatus.playing);
  });

  test('failed playback has an explicit status and preserves the queue',
      () async {
    final playback = FakePlaybackService()..failLoads = true;
    final track = DemoMusicCatalog.tracks.first;
    final controller = PlayerController(
      catalog: DemoMusicCatalog(),
      playback: playback,
    );
    addTearDown(controller.dispose);

    await controller.playTrack(track, queue: [track]);

    expect(controller.status, PlaybackStatus.failed);
    expect(controller.snapshot.status, PlaybackStatus.failed);
    expect(controller.snapshot.currentTrack, same(track));
    expect(controller.snapshot.queue, [track]);
    expect(controller.error, isNotNull);
  });

  test('previous restarts the current track after three seconds', () async {
    final playback = FakePlaybackService();
    final controller =
        PlayerController(catalog: DemoMusicCatalog(), playback: playback);
    addTearDown(controller.dispose);

    await controller.playTrack(DemoMusicCatalog.tracks[1],
        queue: DemoMusicCatalog.tracks);
    playback.position.add(const Duration(seconds: 4));
    await Future<void>.delayed(Duration.zero);

    await controller.skipPrevious();

    expect(playback.seekPositions, [Duration.zero]);
    expect(controller.currentTrack?.title, 'Amber Static');
  });

  test('completed playback advances to the next queue item', () async {
    final playback = FakePlaybackService();
    final catalog = DemoMusicCatalog();
    final controller = PlayerController(catalog: catalog, playback: playback);
    addTearDown(controller.dispose);

    await controller.playTrack(DemoMusicCatalog.tracks.first,
        queue: DemoMusicCatalog.tracks);
    playback.completed.add(true);
    await Future<void>.delayed(Duration.zero);

    expect(controller.currentTrack?.title, 'Amber Static');
  });

  test('queue actions preserve the current track and ordered up-next items',
      () async {
    final playback = FakePlaybackService();
    final first = DemoMusicCatalog.tracks[0];
    final second = DemoMusicCatalog.tracks[1];
    final third = DemoMusicCatalog.tracks[2];
    final fourth = DemoMusicCatalog.tracks[3];
    final controller = PlayerController(
      catalog: DemoMusicCatalog(),
      playback: playback,
    );
    addTearDown(controller.dispose);

    await controller.playTrack(first, queue: [first, third]);
    await Future<void>.delayed(Duration.zero);
    controller.playNext(second);
    controller.addToQueue(fourth);
    controller.addToQueue(second);

    expect(controller.queue, [first, second, third, fourth]);

    controller.removeFromQueue(second);
    expect(controller.queue, [first, third, fourth]);

    controller.removeFromQueue(first);
    expect(controller.currentTrack, same(first));
    expect(controller.status, PlaybackStatus.playing);
    expect(controller.hasNext, isTrue);

    await controller.skipNext();
    await Future<void>.delayed(Duration.zero);
    expect(controller.currentTrack, same(third));
    expect(controller.queue, [third, fourth]);

    controller.clearQueue();
    expect(controller.queue, isEmpty);
    expect(controller.currentTrack, same(third));
    expect(controller.hasNext, isFalse);
    expect(controller.status, PlaybackStatus.playing);
  });

  test('play next moves an already queued track', () async {
    final playback = FakePlaybackService();
    final first = DemoMusicCatalog.tracks[0];
    final second = DemoMusicCatalog.tracks[1];
    final third = DemoMusicCatalog.tracks[2];
    final controller = PlayerController(
      catalog: DemoMusicCatalog(),
      playback: playback,
    );
    addTearDown(controller.dispose);

    await controller.playTrack(first, queue: [first, second, third]);
    controller.playNext(third);

    expect(controller.queue, [first, third, second]);
  });

  test('library saves and removes tracks without changing the queue', () async {
    final playback = FakePlaybackService();
    final catalog = DemoMusicCatalog();
    final controller = PlayerController(catalog: catalog, playback: playback);
    addTearDown(controller.dispose);

    controller.toggleLibrary(DemoMusicCatalog.tracks.first);
    expect(controller.library, [DemoMusicCatalog.tracks.first]);
    expect(controller.queue, isEmpty);

    controller.toggleLibrary(DemoMusicCatalog.tracks.first);
    expect(controller.library, isEmpty);
  });
}

class FakePlaybackService implements PlaybackService {
  final position = StreamController<Duration>.broadcast();
  final duration = StreamController<Duration?>.broadcast();
  final playing = StreamController<bool>.broadcast();
  final status = StreamController<PlaybackStatus>.broadcast();
  final completed = StreamController<bool>.broadcast();
  final loaded = <Track>[];
  final seekPositions = <Duration>[];
  Completer<void>? loadGate;
  bool failLoads = false;

  @override
  Stream<Duration> get positionStream => position.stream;

  @override
  Stream<Duration?> get durationStream => duration.stream;

  @override
  Stream<bool> get playingStream => playing.stream;

  @override
  Stream<PlaybackStatus> get statusStream => status.stream;

  @override
  Stream<bool> get completedStream => completed.stream;

  @override
  Future<void> load(Track track) async {
    loaded.add(track);
    if (failLoads) {
      throw StateError('load failed');
    }
    status.add(PlaybackStatus.loading);
    final gate = loadGate;
    if (gate != null) {
      await gate.future;
    }
    duration.add(track.duration);
    position.add(Duration.zero);
  }

  @override
  Future<void> play() async {
    playing.add(true);
    status.add(PlaybackStatus.playing);
  }

  @override
  Future<void> pause() async {
    playing.add(false);
    status.add(PlaybackStatus.paused);
  }

  @override
  Future<void> seek(Duration value) async => seekPositions.add(value);

  @override
  Future<void> dispose() async {
    await position.close();
    await duration.close();
    await playing.close();
    await status.close();
    await completed.close();
  }
}

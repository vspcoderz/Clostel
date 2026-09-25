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

    expect(controller.currentTrack?.title, 'Night Transit');
    expect(controller.isPlaying, isTrue);
    expect(playback.loaded, [DemoMusicCatalog.tracks.first]);
    expect(controller.hasNext, isTrue);

    await controller.skipNext();

    expect(controller.currentTrack?.title, 'Amber Static');
    expect(playback.loaded,
        [DemoMusicCatalog.tracks.first, DemoMusicCatalog.tracks[1]]);
    expect(controller.isPlaying, isTrue);
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
  final completed = StreamController<bool>.broadcast();
  final loaded = <Track>[];
  final seekPositions = <Duration>[];

  @override
  Stream<Duration> get positionStream => position.stream;

  @override
  Stream<Duration?> get durationStream => duration.stream;

  @override
  Stream<bool> get playingStream => playing.stream;

  @override
  Stream<bool> get completedStream => completed.stream;

  @override
  Future<void> load(Track track) async {
    loaded.add(track);
    duration.add(track.duration);
    position.add(Duration.zero);
  }

  @override
  Future<void> play() async => playing.add(true);

  @override
  Future<void> pause() async => playing.add(false);

  @override
  Future<void> seek(Duration value) async => seekPositions.add(value);

  @override
  Future<void> dispose() async {
    await position.close();
    await duration.close();
    await playing.close();
    await completed.close();
  }
}

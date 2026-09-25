import 'dart:async';

import 'package:clostel/core/data/demo_catalog.dart';
import 'package:clostel/core/models/track.dart';
import 'package:clostel/core/services/music_download_service.dart';
import 'package:clostel/core/services/playback_service.dart';
import 'package:clostel/features/player/player_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes download progress and the completed path', () async {
    final track = _youtubeTrack();
    final gate = Completer<String>();
    final downloads = _FakeMusicDownloadService(gate: gate);
    final controller = PlayerController(
      catalog: DemoMusicCatalog(),
      playback: _FakePlaybackService(),
      musicDownload: downloads,
    );
    addTearDown(controller.dispose);

    final operation = controller.downloadTrack(track);

    expect(controller.isDownloading, isTrue);
    expect(controller.isTrackDownloading(track), isTrue);
    expect(controller.downloadingTrackIds, {track.id});
    expect(controller.downloadError, isNull);
    expect(downloads.requested, [track]);

    gate.complete('/application-data/Clostel/downloads/track.mp3');
    expect(await operation, endsWith('track.mp3'));
    expect(controller.isDownloading, isFalse);
    expect(controller.downloadingTrackIds, isEmpty);
    expect(controller.lastDownloadedPath, endsWith('track.mp3'));
    expect(controller.downloadError, isNull);
  });

  test('clears download progress and exposes a service error', () async {
    final track = _youtubeTrack();
    final downloads = _FakeMusicDownloadService(error: StateError('failed'));
    final controller = PlayerController(
      catalog: DemoMusicCatalog(),
      playback: _FakePlaybackService(),
      musicDownload: downloads,
    );
    addTearDown(controller.dispose);

    expect(await controller.downloadTrack(track), isNull);

    expect(controller.isDownloading, isFalse);
    expect(controller.downloadError, 'Could not download Track title.');
    expect(controller.lastDownloadedPath, isNull);

    controller.clearDownloadError();
    expect(controller.downloadError, isNull);
  });

  test('does not call the service for an unsupported track', () async {
    final downloads = _FakeMusicDownloadService();
    final controller = PlayerController(
      catalog: DemoMusicCatalog(),
      playback: _FakePlaybackService(),
      musicDownload: downloads,
    );
    addTearDown(controller.dispose);

    expect(
      await controller.downloadTrack(DemoMusicCatalog.tracks.first),
      isNull,
    );

    expect(downloads.requested, isEmpty);
    expect(controller.isDownloading, isFalse);
    expect(controller.downloadError, 'This track cannot be downloaded.');
  });
}

Track _youtubeTrack() {
  return const Track(
    id: 'yt-dlp-abc123',
    title: 'Track title',
    artist: 'Track artist',
    album: 'YouTube search',
    genre: 'YouTube',
    duration: Duration(minutes: 3),
    accentValue: 0xFF000000,
    source: 'yt-dlp',
    sourceUrl: 'https://youtu.be/abc123',
  );
}

class _FakeMusicDownloadService implements MusicDownloadService {
  _FakeMusicDownloadService({this.gate, this.error});

  final Completer<String>? gate;
  final Object? error;
  final requested = <Track>[];

  @override
  Future<String> download(Track track) async {
    requested.add(track);
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return gate?.future ?? '/downloads/${track.id}.mp3';
  }

  @override
  bool supports(Track track) => track.source == 'yt-dlp';
}

class _FakePlaybackService implements PlaybackService {
  final position = StreamController<Duration>.broadcast();
  final duration = StreamController<Duration?>.broadcast();
  final playing = StreamController<bool>.broadcast();
  final status = StreamController<PlaybackStatus>.broadcast();
  final completed = StreamController<bool>.broadcast();

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
  Future<void> load(Track track) async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> dispose() async {
    await position.close();
    await duration.close();
    await playing.close();
    await status.close();
    await completed.close();
  }
}

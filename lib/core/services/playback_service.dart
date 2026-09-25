import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../models/track.dart';
import 'track_file_resolver.dart';

enum PlaybackStatus {
  idle,
  loading,
  buffering,
  playing,
  paused,
  failed,
  ended,
}

abstract interface class PlaybackService {
  Stream<Duration> get positionStream;

  Stream<Duration?> get durationStream;

  Stream<bool> get playingStream;

  Stream<PlaybackStatus> get statusStream;

  Stream<bool> get completedStream;

  Future<void> load(Track track);

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> dispose();
}

class JustAudioPlaybackService implements PlaybackService {
  JustAudioPlaybackService(
      {Iterable<TrackFileResolver> fileResolvers = const []})
      : _player = AudioPlayer(),
        _fileResolvers = List<TrackFileResolver>.unmodifiable(fileResolvers);

  final AudioPlayer _player;
  final List<TrackFileResolver> _fileResolvers;

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Stream<bool> get playingStream =>
      _player.playerStateStream.map((state) => state.playing);

  @override
  Stream<PlaybackStatus> get statusStream =>
      Stream<PlaybackStatus>.multi((controller) {
        final playerStateSubscription = _player.playerStateStream.listen(
          (state) {
            controller.add(_statusFromPlayerState(state));
          },
          onDone: controller.close,
        );
        final errorSubscription = _player.errorStream.listen(
          (_) {
            controller.add(PlaybackStatus.failed);
          },
          onDone: controller.close,
        );

        controller.onCancel = () async {
          await playerStateSubscription.cancel();
          await errorSubscription.cancel();
        };
      }).distinct();

  @override
  Stream<bool> get completedStream => _player.playerStateStream
      .map((state) => state.processingState == ProcessingState.completed)
      .distinct();

  @override
  Future<void> load(Track track) async {
    if (track.playbackKind == PlaybackKind.unknown) {
      throw StateError(
          'This provider does not expose a verified playback file.');
    }

    var filePath = track.filePath;
    if (filePath == null) {
      for (final resolver in _fileResolvers) {
        if (resolver.supports(track)) {
          filePath = await resolver.resolve(track);
          break;
        }
      }
    }

    final source = filePath != null
        ? AudioSource.file(filePath)
        : track.streamUrl != null
            ? AudioSource.uri(Uri.parse(track.streamUrl!))
            : track.assetPath != null
                ? AudioSource.asset(track.assetPath!)
                : throw StateError('Track ${track.id} has no playable source.');

    await _player.setAudioSource(source);
  }

  @override
  Future<void> play() {
    // just_audio's play future lives until playback pauses or completes. The
    // service exposes a command instead, while statusStream reports later
    // failures and completion independently.
    final playback = _player.play();
    unawaited(playback.catchError((Object _) {}));
    return Future<void>.value();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> dispose() async {
    await _player.dispose();
    for (final resolver in _fileResolvers) {
      await resolver.dispose();
    }
  }
}

PlaybackStatus _statusFromPlayerState(PlayerState state) {
  return switch (state.processingState) {
    ProcessingState.idle => PlaybackStatus.idle,
    ProcessingState.loading => PlaybackStatus.loading,
    ProcessingState.buffering => PlaybackStatus.buffering,
    ProcessingState.ready =>
      state.playing ? PlaybackStatus.playing : PlaybackStatus.paused,
    ProcessingState.completed => PlaybackStatus.ended,
  };
}

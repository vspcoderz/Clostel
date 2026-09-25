import 'package:just_audio/just_audio.dart';

import '../models/track.dart';
import 'track_file_resolver.dart';

abstract interface class PlaybackService {
  Stream<Duration> get positionStream;

  Stream<Duration?> get durationStream;

  Stream<bool> get playingStream;

  Stream<bool> get completedStream;

  Future<void> load(Track track);

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> dispose();
}

class JustAudioPlaybackService implements PlaybackService {
  JustAudioPlaybackService({Iterable<TrackFileResolver> fileResolvers = const []})
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
  Stream<bool> get completedStream => _player.playerStateStream
      .map((state) => state.processingState == ProcessingState.completed)
      .distinct();

  @override
  Future<void> load(Track track) async {
    if (track.playbackKind == PlaybackKind.unknown) {
      throw StateError('This provider does not expose a verified playback file.');
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
  Future<void> play() => _player.play();

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

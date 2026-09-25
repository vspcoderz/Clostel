import 'package:just_audio/just_audio.dart';

import '../models/track.dart';

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
  JustAudioPlaybackService() : _player = AudioPlayer();

  final AudioPlayer _player;

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
    await _player.setAudioSource(AudioSource.asset(track.assetPath));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> dispose() => _player.dispose();
}

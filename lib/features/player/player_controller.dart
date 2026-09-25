import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/models/track.dart';
import '../../core/services/music_catalog.dart';
import '../../core/services/local_music_service.dart';
import '../../core/services/playback_service.dart';

@immutable
class PlayerSnapshot {
  PlayerSnapshot({
    required this.status,
    required this.currentTrack,
    required List<Track> queue,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.isLoading,
    required this.error,
    required this.hasNext,
    required this.hasPrevious,
  }) : queue = List<Track>.unmodifiable(queue);

  final PlaybackStatus status;
  final Track? currentTrack;
  final List<Track> queue;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isLoading;
  final String? error;
  final bool hasNext;
  final bool hasPrevious;
}

class PlayerController extends ChangeNotifier {
  PlayerController({
    required MusicCatalog catalog,
    required PlaybackService playback,
    LocalMusicService? localMusic,
  })  : _catalog = catalog,
        _playback = playback,
        _localMusic = localMusic {
    _positionSubscription = _playback.positionStream.listen((position) {
      _position = position;
      _notify();
    });
    _durationSubscription = _playback.durationStream.listen((duration) {
      if (duration != null) {
        _duration = duration;
        _notify();
      }
    });
    _statusSubscription = _playback.statusStream.listen((status) {
      if (_status == status) {
        return;
      }
      _status = status;
      _notify();
    });
    _playingSubscription = _playback.playingStream.listen((playing) {
      _isPlaying = playing;
      _notify();
    });
    _completedSubscription = _playback.completedStream.listen((completed) {
      if (completed) {
        unawaited(skipNext());
      }
    });
  }

  final MusicCatalog _catalog;
  final PlaybackService _playback;
  final LocalMusicService? _localMusic;

  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration?> _durationSubscription;
  late final StreamSubscription<PlaybackStatus> _statusSubscription;
  late final StreamSubscription<bool> _playingSubscription;
  late final StreamSubscription<bool> _completedSubscription;

  List<Track> _featured = const [];
  List<Track> _searchResults = const [];
  List<Track> _queue = const [];
  List<Track> _library = const [];
  Track? _currentTrack;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  PlaybackStatus _status = PlaybackStatus.idle;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isImportingLibrary = false;
  int _searchRequest = 0;
  int _playRequest = 0;
  bool _disposed = false;
  Timer? _searchDebounce;
  Future<void> _playbackTail = Future<void>.value();
  String? _error;

  List<Track> get featured => _featured;
  List<Track> get searchResults => _searchResults;
  List<Track> get queue => _queue;
  List<Track> get library => _library;
  Track? get currentTrack => _currentTrack;
  Duration get position => _position;
  Duration get duration => _duration;
  PlaybackStatus get status => _status;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isImportingLibrary => _isImportingLibrary;
  String? get error => _error;

  PlayerSnapshot get snapshot => PlayerSnapshot(
        status: _status,
        currentTrack: _currentTrack,
        queue: _queue,
        position: _position,
        duration: _duration,
        isPlaying: _isPlaying,
        isLoading: _isLoading,
        error: _error,
        hasNext: hasNext,
        hasPrevious: hasPrevious,
      );

  bool isSaved(Track track) => _library.any((item) => item.id == track.id);

  bool get hasNext {
    final current = _currentTrack;
    if (current == null || _queue.isEmpty) {
      return false;
    }
    final currentIndex = _queue.indexWhere((track) => track.id == current.id);
    return currentIndex < 0 || currentIndex < _queue.length - 1;
  }

  bool get hasPrevious {
    final current = _currentTrack;
    if (current == null || _queue.isEmpty) {
      return false;
    }
    return _queue.indexWhere((track) => track.id == current.id) > 0;
  }

  Future<void> loadFeatured() async {
    if (_featured.isNotEmpty || _isLoading) {
      return;
    }

    _isLoading = true;
    _error = null;
    _notify();

    try {
      _featured = await _catalog.getFeatured();
      if (_searchRequest == 0) {
        _searchResults = _featured;
      }
    } catch (_) {
      _error = 'Could not load the catalog. Try again.';
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  void search(String query) {
    final request = ++_searchRequest;
    _searchDebounce?.cancel();
    _isSearching = true;
    _error = null;
    _notify();

    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_runSearch(query, request)),
    );
  }

  Future<void> _runSearch(String query, int request) async {
    try {
      final results = await _catalog.search(query);
      if (request == _searchRequest) {
        _searchResults = results;
      }
    } catch (_) {
      if (request == _searchRequest) {
        _error = 'Search is unavailable right now.';
      }
    } finally {
      if (request == _searchRequest) {
        _isSearching = false;
        _notify();
      }
    }
  }

  Future<void> playTrack(Track track, {List<Track>? queue}) async {
    final request = ++_playRequest;

    if (queue != null) {
      _queue = List<Track>.unmodifiable(queue);
    } else if (!_queue.any((item) => item.id == track.id)) {
      _queue = List<Track>.unmodifiable([..._queue, track]);
    }

    _currentTrack = track;
    _position = Duration.zero;
    _duration = track.duration;
    _status = PlaybackStatus.loading;
    _isLoading = true;
    _error = null;
    _notify();

    final operation = _playbackTail.then<void>((_) async {
      if (request != _playRequest) {
        return;
      }
      await _playback.load(track);
      if (request != _playRequest) {
        return;
      }
      await _playback.play();
      if (request != _playRequest) {
        return;
      }
      _isPlaying = true;
      _status = PlaybackStatus.playing;
    });
    _playbackTail = operation.catchError((Object _) {});

    try {
      await operation;
    } catch (_) {
      if (request != _playRequest) {
        return;
      }
      _currentTrack = null;
      _position = Duration.zero;
      _duration = Duration.zero;
      _isPlaying = false;
      _status = PlaybackStatus.failed;
      _error = 'This track could not be played.';
      _notify();
    } finally {
      if (request == _playRequest) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<void> togglePlayback() async {
    if (_isLoading) {
      return;
    }

    final current = _currentTrack;
    if (current == null) {
      if (_featured.isNotEmpty) {
        await playTrack(_featured.first, queue: _featured);
      }
      return;
    }

    try {
      if (_isPlaying) {
        await _playback.pause();
      } else {
        await _playback.play();
      }
    } catch (_) {
      _status = PlaybackStatus.failed;
      _error = 'Playback controls are unavailable right now.';
      _notify();
    }
  }

  Future<void> skipNext() async {
    final current = _currentTrack;
    if (current == null || !hasNext) {
      return;
    }

    final currentIndex = _queue.indexWhere((track) => track.id == current.id);
    final nextIndex = currentIndex < 0 ? 0 : currentIndex + 1;
    await playTrack(_queue[nextIndex]);
  }

  Future<void> skipPrevious() async {
    final current = _currentTrack;
    if (current == null || _queue.isEmpty) {
      return;
    }

    if (_position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return;
    }

    final index = _queue.indexWhere((track) => track.id == current.id);
    final previousIndex = index > 0 ? index - 1 : _queue.length - 1;
    await playTrack(_queue[previousIndex]);
  }

  Future<void> seek(Duration value) async {
    try {
      await _playback.seek(value);
    } catch (_) {
      _status = PlaybackStatus.failed;
      _error = 'Could not move the playback position.';
      _notify();
    }
  }

  /// Clears queued tracks without interrupting the currently loaded track.
  void clearQueue() {
    if (_queue.isEmpty) {
      return;
    }
    _queue = const [];
    _notify();
  }

  /// Removes matching queued tracks without interrupting current playback.
  void removeFromQueue(Track track) {
    final updatedQueue = _queue
        .where((queuedTrack) => queuedTrack.id != track.id)
        .toList(growable: false);
    if (updatedQueue.length == _queue.length) {
      return;
    }
    _queue = List<Track>.unmodifiable(updatedQueue);
    _notify();
  }

  void addToQueue(Track track) {
    if (_queue.any((queuedTrack) => queuedTrack.id == track.id)) {
      return;
    }
    _queue = List<Track>.unmodifiable([..._queue, track]);
    _notify();
  }

  void playNext(Track track) {
    if (_queue.any((queuedTrack) => queuedTrack.id == track.id)) {
      return;
    }

    final current = _currentTrack;
    final currentIndex = current == null
        ? -1
        : _queue.indexWhere((queuedTrack) => queuedTrack.id == current.id);
    final insertionIndex = currentIndex < 0 ? 0 : currentIndex + 1;
    final updatedQueue = [..._queue]..insert(insertionIndex, track);
    _queue = List<Track>.unmodifiable(updatedQueue);
    _notify();
  }

  Future<void> importLocalTracks() async {
    final localMusic = _localMusic;
    if (localMusic == null || _isImportingLibrary) {
      return;
    }

    _isImportingLibrary = true;
    _error = null;
    _notify();

    try {
      final imported = await localMusic.pickAudioFiles();
      if (imported.isNotEmpty) {
        final existingIds = _library.map((track) => track.id).toSet();
        _library = List<Track>.unmodifiable([
          ..._library,
          ...imported.where((track) => !existingIds.contains(track.id)),
        ]);
      }
    } catch (_) {
      _error = 'Could not import those audio files.';
    } finally {
      _isImportingLibrary = false;
      _notify();
    }
  }

  void toggleLibrary(Track track) {
    if (isSaved(track)) {
      _library = List<Track>.unmodifiable(
        _library.where((item) => item.id != track.id),
      );
    } else {
      _library = List<Track>.unmodifiable([..._library, track]);
    }
    _notify();
  }

  void clearError() {
    _error = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _searchDebounce?.cancel();
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _statusSubscription.cancel();
    _playingSubscription.cancel();
    _completedSubscription.cancel();
    unawaited(_playback.dispose());
    super.dispose();
  }
}

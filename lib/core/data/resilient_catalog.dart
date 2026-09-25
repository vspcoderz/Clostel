import '../models/track.dart';
import '../services/music_catalog.dart';

class ResilientMusicCatalog implements MusicCatalog {
  const ResilientMusicCatalog({
    required this.primary,
    required this.fallback,
  });

  final MusicCatalog primary;
  final MusicCatalog fallback;

  @override
  Future<List<Track>> getFeatured() async {
    try {
      final tracks = await primary.getFeatured();
      if (tracks.isNotEmpty) {
        return tracks;
      }
    } catch (_) {
      // The local catalog keeps the app useful when the network is unavailable.
    }
    return fallback.getFeatured();
  }

  @override
  Future<List<Track>> search(String query) async {
    try {
      final tracks = await primary.search(query);
      if (tracks.isNotEmpty) {
        return tracks;
      }
    } catch (_) {
      // Fall through to the local catalog for offline development.
    }
    return fallback.search(query);
  }
}

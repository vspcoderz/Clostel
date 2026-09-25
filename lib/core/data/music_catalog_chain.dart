import '../models/track.dart';
import '../services/music_catalog.dart';

class MusicCatalogChain implements MusicCatalog {
  const MusicCatalogChain({required this.sources});

  final List<MusicCatalog> sources;

  @override
  Future<List<Track>> getFeatured() async {
    for (final source in sources) {
      try {
        final tracks = await source.getFeatured();
        if (tracks.isNotEmpty) {
          return tracks;
        }
      } catch (_) {
        // Try the next configured provider.
      }
    }
    return const [];
  }

  @override
  Future<List<Track>> search(String query) async {
    for (final source in sources) {
      try {
        final tracks = await source.search(query);
        if (tracks.isNotEmpty) {
          return tracks;
        }
      } catch (_) {
        // Try the next configured provider.
      }
    }
    return const [];
  }
}

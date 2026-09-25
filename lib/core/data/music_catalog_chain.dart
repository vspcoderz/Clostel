import '../models/track.dart';
import '../services/music_catalog.dart';

class MusicCatalogChain implements MusicCatalog {
  const MusicCatalogChain({
    required this.sources,
    this.maxResults = 60,
    this.perSourceLimit = 10,
  });

  final List<MusicCatalog> sources;
  final int maxResults;
  final int perSourceLimit;

  @override
  Future<List<Track>> getFeatured() => _collect((source) => source.getFeatured());

  @override
  Future<List<Track>> search(String query) =>
      _collect((source) => source.search(query));

  Future<List<Track>> _collect(
    Future<List<Track>> Function(MusicCatalog source) load,
  ) async {
    final seenIds = <String>{};
    final results = <Track>[];

    for (final source in sources) {
      try {
        final tracks = await load(source);
        for (final track in tracks.take(perSourceLimit)) {
          if (seenIds.add(track.id)) {
            results.add(track);
          }
          if (results.length >= maxResults) {
            return List<Track>.unmodifiable(results);
          }
        }
      } catch (_) {
        // Try the next configured provider.
      }
    }

    return List<Track>.unmodifiable(results);
  }
}

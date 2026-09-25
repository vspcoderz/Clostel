import '../models/track.dart';

abstract interface class MusicCatalog {
  Future<List<Track>> getFeatured();

  Future<List<Track>> search(String query);
}

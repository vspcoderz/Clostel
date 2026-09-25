import '../models/track.dart';

abstract interface class TrackFileResolver {
  bool supports(Track track);

  Future<String> resolve(Track track);

  Future<void> dispose();
}

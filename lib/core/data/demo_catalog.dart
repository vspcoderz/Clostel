import '../models/track.dart';
import '../services/music_catalog.dart';

class DemoMusicCatalog implements MusicCatalog {
  static const tracks = <Track>[
    Track(
      id: 'signal-bloom-01',
      title: 'Night Transit',
      artist: 'Sora Vale',
      album: 'Signal Bloom',
      genre: 'Electronic',
      duration: Duration(seconds: 24),
      assetPath: 'assets/audio/night_transit.wav',
      accentValue: 0xFFC8F36A,
    ),
    Track(
      id: 'signal-bloom-02',
      title: 'Amber Static',
      artist: 'Sora Vale',
      album: 'Signal Bloom',
      genre: 'Downtempo',
      duration: Duration(seconds: 32),
      assetPath: 'assets/audio/amber_static.wav',
      accentValue: 0xFFF2A65A,
    ),
    Track(
      id: 'signal-bloom-03',
      title: 'Low Orbit',
      artist: 'Mina Kade',
      album: 'Soft Machines',
      genre: 'Ambient',
      duration: Duration(seconds: 20),
      assetPath: 'assets/audio/low_orbit.wav',
      accentValue: 0xFF8CD9D6,
    ),
    Track(
      id: 'signal-bloom-04',
      title: 'Afterimage',
      artist: 'Kito North',
      album: 'Rooms Without Walls',
      genre: 'Indie',
      duration: Duration(seconds: 28),
      assetPath: 'assets/audio/afterimage.wav',
      accentValue: 0xFFE88C9A,
    ),
  ];

  @override
  Future<List<Track>> getFeatured() async => tracks;

  @override
  Future<List<Track>> search(String query) async {
    return tracks.where((track) => track.matches(query)).toList();
  }
}

import 'package:flutter_test/flutter_test.dart';

import 'package:clostel/core/data/deezer_catalog.dart';

void main() {
  test('normalizes a real Deezer track and keeps only safe media URLs', () {
    final track = DeezerMusicCatalog.parseTrack({
      'id': 12345,
      'title': 'Night Signal',
      'duration': 42,
      'preview': 'https://cdn.deezer.com/track/preview.mp3',
      'artist': {'name': 'Sora Vale'},
      'album': {
        'title': 'Signal Bloom',
        'cover_xl': 'https://cdn.deezer.com/cover.jpg',
      },
    });

    expect(track, isNotNull);
    expect(track!.id, 'deezer-12345');
    expect(track.title, 'Night Signal');
    expect(track.artist, 'Sora Vale');
    expect(track.streamUrl, contains('https://'));
    expect(track.artworkUrl, contains('https://'));
    expect(track.isPreview, isTrue);
  });

  test('rejects tracks without a safe preview URL', () {
    final track = DeezerMusicCatalog.parseTrack({
      'id': 12345,
      'title': 'Night Signal',
      'preview': 'file:///tmp/local.mp3',
      'artist': {'name': 'Sora Vale'},
      'album': {'title': 'Signal Bloom'},
    });

    expect(track, isNull);
  });
}

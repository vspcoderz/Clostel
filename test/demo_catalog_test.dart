import 'package:flutter_test/flutter_test.dart';

import 'package:clostel/core/data/demo_catalog.dart';

void main() {
  test('demo catalog exposes a deterministic featured list', () async {
    final catalog = DemoMusicCatalog();

    final tracks = await catalog.getFeatured();

    expect(tracks, isNotEmpty);
    expect(tracks.map((track) => track.id).toSet().length, tracks.length);
    expect(
        tracks.every(
            (track) => track.assetPath?.startsWith('assets/audio/') == true),
        isTrue);
  });

  test('catalog search matches artist, title, album, and genre', () async {
    final catalog = DemoMusicCatalog();

    expect(await catalog.search('ambient'), hasLength(1));
    expect(await catalog.search('mina'), hasLength(1));
    expect(await catalog.search('nothing here'), isEmpty);
  });
}

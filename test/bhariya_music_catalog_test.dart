import 'dart:convert';

import 'package:clostel/core/data/bhariya_music_catalog.dart';
import 'package:clostel/core/models/track.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('does not call a service when its URL is not configured', () async {
    var called = false;
    final catalog = BhariyaMusicCatalog(
      apiBaseUrl: '',
      client: MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }),
    );

    expect(catalog.isConfigured, isFalse);
    expect(await catalog.search('a song'), isEmpty);
    expect(called, isFalse);
  });

  test('parses prepare and fetch responses as metadata-only by default',
      () async {
    final requests = <http.BaseRequest>[];
    final catalog = BhariyaMusicCatalog(
      apiBaseUrl: 'https://music.example.test/music/',
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.pathSegments.contains('prepare')) {
          return http.Response(
            jsonEncode({'ID': 'song-1'}),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'ID': 'song-1',
            'SONG_NAME': 'A Song',
            'DURATION': 201.5,
            'AUDIO_URL': 'https://cdn.example.test/song-1.mp3',
            'THUMBNAIL': 'https://images.example.test/song-1.jpg',
            'YT_ID': 'yt-1',
            'SPOTIFY_ID': 'spotify-1',
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }),
    );

    final tracks = await catalog.search('A Song');

    expect(tracks, hasLength(1));
    final track = tracks.single;
    expect(track.id, 'bhariya-song-1');
    expect(track.title, 'A Song');
    expect(track.duration, const Duration(seconds: 202));
    expect(track.source, 'BhariyaMusic');
    expect(track.sourceUrl, isNull);
    expect(track.artworkUrl, contains('images.example.test'));
    expect(track.streamUrl, isNull);
    expect(track.playbackKind, PlaybackKind.unknown);
    expect(track.licenseName, 'Experimental rights boundary');
    expect(track.attribution, contains('yt-1'));
    expect(track.attribution, contains('Rights are not verified'));
    expect(requests, hasLength(2));
    expect(requests.first.headers['cookie'], isNull);
    expect(requests.first.headers['authorization'], isNull);
  });

  test('uses validated response or service audio only when explicitly enabled',
      () async {
    final requests = <http.BaseRequest>[];
    final catalog = BhariyaMusicCatalog(
      apiBaseUrl: 'https://music.example.test',
      audioEnabled: true,
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.pathSegments.contains('prepare')) {
          return http.Response(
            jsonEncode({'ID': 'song-2'}),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'ID': 'song-2',
            'SONG_NAME': 'Opted In',
            'AUDIO_URL': 'file:///private/audio.mp3',
            'THUMBNAIL': 'javascript:alert(1)',
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }),
    );

    final tracks = await catalog.search('Opted In');

    expect(tracks, hasLength(1));
    final track = tracks.single;
    expect(track.streamUrl, 'https://music.example.test/api/audio/song-2');
    expect(track.playbackKind, PlaybackKind.full);
    expect(track.artworkUrl, isNull);
    expect(requests, hasLength(2));
  });

  test('rejects unsafe prepared IDs and invalid base URLs', () {
    expect(
      BhariyaMusicCatalog.parsePreparedId({'ID': '../other-song'}),
      isNull,
    );
    expect(
      BhariyaMusicCatalog.parsePreparedId({'ID': 'https://example.test/song'}),
      isNull,
    );
    expect(
      const BhariyaMusicCatalog(
        apiBaseUrl: 'https://user:pass@example.test',
      ).isConfigured,
      isFalse,
    );
    expect(
      const BhariyaMusicCatalog(
        apiBaseUrl: 'https://example.test/path?discarded=value',
      ).isConfigured,
      isFalse,
    );
    expect(
      const BhariyaMusicCatalog(
        apiBaseUrl: 'http://remote.example.test',
      ).isConfigured,
      isFalse,
    );
  });

  test('parses a valid response URL without trusting unsafe variants', () {
    final track = BhariyaMusicCatalog.parseFetchResponse(
      {
        'data': {
          'id': 'song-3',
          'title': 'Provenance',
          'source_url': 'https://source.example.test/song-3',
          'artwork_url': 'ftp://images.example.test/cover.jpg',
        },
      },
      preparedId: 'song-3',
      sourceUrl: 'https://music.example.test/api/prepare/song-3',
    );

    expect(track, isNotNull);
    expect(track!.sourceUrl, 'https://source.example.test/song-3');
    expect(track.artworkUrl, isNull);
    expect(track.streamUrl, isNull);
    expect(track.playbackKind, PlaybackKind.unknown);

    final audioWithoutBase = BhariyaMusicCatalog.parseFetchResponse(
      {
        'id': 'song-4',
        'title': 'No base URL',
        'audio_url': 'https://cdn.example.test/song-4.mp3',
      },
      audioEnabled: true,
    );
    expect(audioWithoutBase!.streamUrl, isNull);
    expect(audioWithoutBase.playbackKind, PlaybackKind.unknown);
  });

  test('keeps the prepared identity when the response id disagrees', () {
    final track = BhariyaMusicCatalog.parseFetchResponse(
      {
        'ID': 'other-song',
        'SONG_NAME': 'Mismatched response',
      },
      preparedId: 'prepared-song',
    );

    expect(track, isNotNull);
    expect(track!.id, 'bhariya-prepared-song');
  });
}

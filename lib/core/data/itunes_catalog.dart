import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/track.dart';
import '../services/music_catalog.dart';
import 'catalog_utils.dart';

class ITunesMusicCatalog implements MusicCatalog {
  static const _limit = 30;

  const ITunesMusicCatalog();

  @override
  Future<List<Track>> getFeatured() => _get('music');

  @override
  Future<List<Track>> search(String query) {
    final normalized = query.trim();
    return _get(normalized.isEmpty ? 'music' : normalized);
  }

  Future<List<Track>> _get(String query) async {
    final uri = Uri.https('itunes.apple.com', '/search', {
      'term': query,
      'entity': 'song',
      'media': 'music',
      'limit': '$_limit',
    });
    final response = await http
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'Clostel/0.1 (music catalog client)',
          },
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError('iTunes Search API returned HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['results'] is! List) {
      throw const FormatException(
        'iTunes Search API returned an unexpected catalog shape.',
      );
    }

    return (decoded['results'] as List)
        .whereType<Map>()
        .map((row) => parseTrack(Map<String, dynamic>.from(row)))
        .whereType<Track>()
        .toList(growable: false);
  }

  static Track? parseTrack(Map<String, dynamic> json) {
    final rawId = json['trackId'];
    final id = rawId is num ? rawId.toString() : stringValue(rawId);
    final title = stringValue(json['trackName']);
    final artist = stringValue(json['artistName']);
    final previewUrl = safeHttpUrl(json['previewUrl']);
    if (id.isEmpty || title.isEmpty || artist.isEmpty || previewUrl == null) {
      return null;
    }

    final durationMillis = json['trackTimeMillis'];
    final duration = durationMillis is num
        ? Duration(milliseconds: durationMillis.round())
        : Duration.zero;
    final artworkUrl = safeHttpUrl(json['artworkUrl100'])?.replaceAll(
          '100x100bb',
          '300x300bb',
        );

    return Track(
      id: 'itunes-$id',
      title: title,
      artist: artist,
      album: stringValue(json['collectionName']).isEmpty
          ? 'iTunes catalog'
          : stringValue(json['collectionName']),
      genre: stringValue(json['primaryGenreName']).isEmpty
          ? 'Music'
          : stringValue(json['primaryGenreName']),
      duration: duration,
      accentValue: accentFor(id),
      streamUrl: previewUrl,
      artworkUrl: artworkUrl,
      source: 'Apple iTunes',
      sourceUrl: safeHttpUrl(json['trackViewUrl']),
      attribution: 'Promotional preview provided courtesy of iTunes.',
      playbackKind: PlaybackKind.preview,
    );
  }
}

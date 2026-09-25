import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/track.dart';
import '../services/music_catalog.dart';
import 'catalog_utils.dart';

class AudiusMusicCatalog implements MusicCatalog {
  const AudiusMusicCatalog({
    this.apiKey = '',
    this.appName = 'Clostel',
  });

  final String apiKey;
  final String appName;

  bool get isConfigured => appName.trim().isNotEmpty;

  @override
  Future<List<Track>> getFeatured() => _get('/tracks/trending');

  @override
  Future<List<Track>> search(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return getFeatured();
    }
    return _get('/tracks/search', query: normalized);
  }

  Future<List<Track>> _get(String path, {String? query}) async {
    if (!isConfigured) {
      throw StateError('Audius app name is not configured.');
    }

    final uri = Uri.https('discoveryprovider.audius.co', '/v1$path', {
      'app_name': appName,
      if (apiKey.trim().isNotEmpty) 'api_key': apiKey,
      if (query != null) 'query': query,
      'limit': '30',
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
      throw StateError('Audius returned HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    final rows = decoded is Map ? decoded['data'] : null;
    if (rows is! List) {
      throw const FormatException(
        'Audius returned an unexpected catalog shape.',
      );
    }

    return rows
        .whereType<Map>()
        .map((row) => parseTrack(Map<String, dynamic>.from(row)))
        .whereType<Track>()
        .toList(growable: false);
  }

  static Track? parseTrack(Map<String, dynamic> json) {
    final id = stringValue(json['id']);
    final title = stringValue(json['title']);
    final user = mapValue(json['user']);
    final artist = stringValue(user?['name']);
    if (json['is_streamable'] == false || json['is_available'] == false) {
      return null;
    }
    final streamUrl = _streamUrl(json, id);
    if (id.isEmpty || title.isEmpty || artist.isEmpty || streamUrl == null) {
      return null;
    }

    final artwork = mapValue(json['artwork']);
    final artworkUrl = safeHttpUrl(artwork?['uri']) ??
        safeHttpUrl(artwork?['1000x1000']) ??
        safeHttpUrl(artwork?['480x480']);
    final license = stringValue(json['license']);
    if (license.isEmpty) {
      return null;
    }
    final permalink = stringValue(json['permalink']);
    final sourceUrl = _sourceUrl(permalink);
    return Track(
      id: 'audius-$id',
      title: title,
      artist: artist,
      album: 'Audius',
      genre: stringValue(json['genre']).isEmpty
          ? 'Open music'
          : stringValue(json['genre']),
      duration: durationFrom(json['duration']),
      accentValue: accentFor(id),
      streamUrl: streamUrl,
      artworkUrl: artworkUrl,
      source: 'Audius',
      sourceUrl: sourceUrl,
      licenseName: license.isEmpty ? null : license,
      playbackKind: PlaybackKind.full,
    );
  }

  static String? _streamUrl(Map<String, dynamic> json, String id) {
    final stream = mapValue(json['stream']);
    final direct = safeHttpUrl(stream?['url']) ??
        safeHttpUrl(json['stream']) ??
        safeHttpUrl(json['stream_url']) ??
        safeHttpUrl(json['streamUrl']);
    if (direct != null) {
      return direct;
    }
    if (id.isEmpty) {
      return null;
    }
    return Uri.https(
      'discoveryprovider.audius.co',
      '/v1/tracks/$id/stream',
    ).toString();
  }

  static String? _sourceUrl(String permalink) {
    final direct = safeHttpUrl(permalink);
    if (direct != null) {
      return direct;
    }
    if (!permalink.startsWith('/')) {
      return null;
    }
    return Uri.https('audius.co', permalink).toString();
  }
}

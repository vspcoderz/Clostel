import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/track.dart';
import '../services/music_catalog.dart';
import 'catalog_utils.dart';

class OpenverseMusicCatalog implements MusicCatalog {
  static const _limit = 30;

  const OpenverseMusicCatalog();

  @override
  Future<List<Track>> getFeatured() {
    return _get(query: 'music');
  }

  @override
  Future<List<Track>> search(String query) {
    final normalized = query.trim();
    return _get(query: normalized.isEmpty ? 'music' : normalized);
  }

  Future<List<Track>> _get({required String query}) async {
    final uri = Uri.https('api.openverse.org', '/v1/audio/', {
      'q': query,
      'page_size': '$_limit',
      'mature': 'false',
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
      throw StateError('Openverse returned HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['results'] is! List) {
      throw const FormatException(
        'Openverse returned an unexpected catalog shape.',
      );
    }

    return (decoded['results'] as List)
        .whereType<Map>()
        .map((row) => parseTrack(Map<String, dynamic>.from(row)))
        .whereType<Track>()
        .toList(growable: false);
  }

  static Track? parseTrack(Map<String, dynamic> json) {
    final id = stringValue(json['id']);
    final title = stringValue(json['title']);
    final creator = stringValue(json['creator']);
    final streamUrl = safeHttpUrl(json['url']);
    if (id.isEmpty || title.isEmpty || creator.isEmpty || streamUrl == null) {
      return null;
    }

    final provider = stringValue(json['provider']);
    final sourceUrl = safeHttpUrl(json['foreign_landing_url']);
    final license = stringValue(json['license']);
    final licenseVersion = stringValue(json['license_version']);
    final licenseUrl = safeHttpUrl(json['license_url']);
    final playbackKind = _playbackKind(provider);
    if (playbackKind == PlaybackKind.full && licenseUrl == null) {
      return null;
    }
    final licenseName = [
      license,
      if (licenseVersion.isNotEmpty) licenseVersion,
    ].join(' ');
    final durationMillis = json['duration'];
    final duration = durationMillis is num
        ? Duration(milliseconds: durationMillis.round())
        : Duration.zero;
    final genres = json['genres'];
    final genre = genres is List && genres.isNotEmpty
        ? genres.whereType<String>().join(', ')
        : stringValue(json['category']);
    final audioSet = mapValue(json['audio_set']);
    final album = stringValue(audioSet?['title']);

    return Track(
      id: 'openverse-$id',
      title: title,
      artist: creator,
      album: album.isEmpty ? 'Openverse catalog' : album,
      genre: genre.isEmpty ? 'Open audio' : genre,
      duration: duration,
      accentValue: accentFor(id),
      streamUrl: streamUrl,
      artworkUrl: safeHttpUrl(json['thumbnail']),
      source: 'Openverse',
      sourceUrl: sourceUrl,
      licenseUrl: licenseUrl,
      licenseName: licenseName.isEmpty ? null : licenseName,
      attribution: stringValue(json['attribution']),
      playbackKind: playbackKind,
    );
  }

  static PlaybackKind _playbackKind(String provider) {
    return switch (provider.toLowerCase()) {
      'jamendo' => PlaybackKind.full,
      'freesound' => PlaybackKind.preview,
      _ => PlaybackKind.unknown,
    };
  }
}

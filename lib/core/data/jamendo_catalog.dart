import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/track.dart';
import '../services/music_catalog.dart';

class JamendoMusicCatalog implements MusicCatalog {
  const JamendoMusicCatalog({required this.clientId});

  final String clientId;

  bool get isConfigured => clientId.trim().isNotEmpty;

  @override
  Future<List<Track>> getFeatured() {
    return _get(
      Uri.https('api.jamendo.com', '/v3.0/tracks/', {
        'client_id': clientId,
        'format': 'json',
        'limit': '30',
        'audioformat': 'mp32',
        'imagesize': '300',
        'order': 'popularity_total',
      }),
    );
  }

  @override
  Future<List<Track>> search(String query) {
    return _get(
      Uri.https('api.jamendo.com', '/v3.0/tracks/', {
        'client_id': clientId,
        'format': 'json',
        'limit': '30',
        'audioformat': 'mp32',
        'imagesize': '300',
        'search': query.trim(),
        'search_type': 'any',
        'order': 'relevance',
      }),
    );
  }

  Future<List<Track>> _get(Uri uri) async {
    if (!isConfigured) {
      throw StateError('Jamendo client ID is not configured.');
    }

    final response =
        await http.get(uri, headers: {'Accept': 'application/json'});
    if (response.statusCode != 200) {
      throw StateError('Jamendo returned HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['results'] is! List<dynamic>) {
      throw const FormatException(
          'Jamendo returned an unexpected catalog shape.');
    }

    return (decoded['results'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(parseTrack)
        .whereType<Track>()
        .toList(growable: false);
  }

  static Track? parseTrack(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is num ? rawId.toString() : _stringValue(rawId);
    final title = _stringValue(json['name']);
    final artist = _stringValue(json['artist_name']);
    final streamUrl = _safeHttpUrl(json['audio']);
    if (id.isEmpty || title.isEmpty || artist.isEmpty || streamUrl == null) {
      return null;
    }

    final durationSeconds =
        json['duration'] is num ? (json['duration'] as num).round() : 0;
    return Track(
      id: 'jamendo-$id',
      title: title,
      artist: artist,
      album: _stringValue(json['album_name']).isEmpty
          ? 'Jamendo catalog'
          : _stringValue(json['album_name']),
      genre: _stringValue(json['music_type']).isEmpty
          ? 'Creative Commons'
          : _stringValue(json['music_type']),
      duration: Duration(seconds: durationSeconds),
      accentValue: 0xFFC6D8D3,
      streamUrl: streamUrl,
      artworkUrl: _safeHttpUrl(json['image']),
      source: 'Jamendo',
      licenseUrl: _safeHttpUrl(json['license_ccurl']),
    );
  }

  static String? _safeHttpUrl(Object? value) {
    final raw = _stringValue(value);
    if (raw.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      return null;
    }
    return raw;
  }

  static String _stringValue(Object? value) => value is String ? value : '';
}

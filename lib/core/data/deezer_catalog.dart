import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/track.dart';
import '../services/music_catalog.dart';

class DeezerMusicCatalog implements MusicCatalog {
  static const _baseUrl = 'https://api.deezer.com';
  static const _accentValues = [
    0xFFEB5E55,
    0xFFD81E5B,
    0xFFC6D8D3,
    0xFFFDF0D5,
    0xFF3A3335,
  ];

  @override
  Future<List<Track>> getFeatured() {
    return _get('/chart/0/tracks?limit=30');
  }

  @override
  Future<List<Track>> search(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return getFeatured();
    }

    final uri = Uri.parse(_baseUrl).replace(
      path: '/search',
      queryParameters: {'q': normalized, 'limit': '30'},
    );
    return _get(uri.toString());
  }

  Future<List<Track>> _get(String pathOrUrl) async {
    final uri = pathOrUrl.startsWith('http')
        ? Uri.parse(pathOrUrl)
        : Uri.parse('$_baseUrl$pathOrUrl');
    final response =
        await http.get(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode != 200) {
      throw StateError('Deezer returned HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['data'] is! List<dynamic>) {
      throw const FormatException(
          'Deezer returned an unexpected catalog shape.');
    }

    return (decoded['data'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(parseTrack)
        .whereType<Track>()
        .toList(growable: false);
  }

  static Track? parseTrack(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is num ? rawId.toString() : _stringValue(rawId);
    final title = _stringValue(json['title']);
    final artist = _mapValue(json['artist']);
    final album = _mapValue(json['album']);
    final artistName = _stringValue(artist?['name']);
    final albumTitle = _stringValue(album?['title']);
    final previewUrl = _safeHttpUrl(json['preview']);

    if (id.isEmpty ||
        title.isEmpty ||
        artistName.isEmpty ||
        previewUrl == null) {
      return null;
    }

    final durationSeconds =
        json['duration'] is num ? (json['duration'] as num).round() : 30;
    final coverUrl = _safeHttpUrl(album?['cover_xl']) ??
        _safeHttpUrl(album?['cover_medium']);

    return Track(
      id: 'deezer-$id',
      title: title,
      artist: artistName,
      album: albumTitle.isEmpty ? 'Deezer catalog' : albumTitle,
      genre: 'Global catalog',
      duration: Duration(seconds: durationSeconds),
      accentValue: _accentValues[id.hashCode.abs() % _accentValues.length],
      streamUrl: previewUrl,
      artworkUrl: coverUrl,
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

  static Map<String, dynamic>? _mapValue(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}

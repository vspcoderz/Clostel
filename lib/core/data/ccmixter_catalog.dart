import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/track.dart';
import '../services/music_catalog.dart';
import 'catalog_utils.dart';

class CcMixterMusicCatalog implements MusicCatalog {
  static const _limit = 30;

  const CcMixterMusicCatalog();

  @override
  Future<List<Track>> getFeatured() {
    return _get('sort=rank&ord=DESC');
  }

  @override
  Future<List<Track>> search(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return getFeatured();
    }
    return _get('search=${Uri.encodeQueryComponent(normalized)}&sort=rank&ord=DESC');
  }

  Future<List<Track>> _get(String query) async {
    final uri = Uri.https('ccmixter.org', '/api/query', {
      'format': 'json',
      'limit': '$_limit',
      'type': 'any',
      ...Uri.parse('?$query').queryParameters,
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
      throw StateError('ccMixter returned HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    final rows = switch (decoded) {
      List<dynamic> value => value,
      Map<String, dynamic> value when value['rows'] is List<dynamic> =>
        value['rows'] as List<dynamic>,
      _ => const <dynamic>[],
    };

    return rows
        .whereType<Map>()
        .map((row) => parseTrack(Map<String, dynamic>.from(row)))
        .whereType<Track>()
        .toList(growable: false);
  }

  static Track? parseTrack(Map<String, dynamic> json) {
    final uploadId = stringValue(json['upload_id']);
    final title = stringValue(json['upload_name']);
    final artist = stringValue(json['user_real_name']).isNotEmpty
        ? stringValue(json['user_real_name'])
        : stringValue(json['user_name']);
    final files = json['files'];
    if (uploadId.isEmpty || title.isEmpty || artist.isEmpty || files is! List) {
      return null;
    }

    _CcMixterFile? file;
    for (final value in files.whereType<Map>()) {
      file = _parseFile(Map<String, dynamic>.from(value));
      if (file != null) {
        break;
      }
    }
    if (file == null) {
      return null;
    }

    final tags = mapValue(json['upload_extra'])?['usertags'];
    final genre = tags is String && tags.isNotEmpty
        ? tags.split(',').first.trim()
        : 'Creative Commons';
    final licenseUrl = safeHttpUrl(json['license_url']);
    final licenseName = stringValue(json['license_name']);
    final pageUrl = safeHttpUrl(json['file_page_url']);
    if (licenseUrl == null) {
      return null;
    }

    return Track(
      id: 'ccmixter-$uploadId',
      title: title,
      artist: artist,
      album: 'ccMixter catalog',
      genre: genre.isEmpty ? 'Creative Commons' : genre,
      duration: file.duration,
      accentValue: accentFor(uploadId),
      streamUrl: file.url,
      source: 'ccMixter',
      sourceUrl: pageUrl,
      licenseUrl: licenseUrl,
      licenseName: licenseName.isEmpty ? null : licenseName,
      attribution: 'Music by $artist on ccMixter.',
      playbackKind: PlaybackKind.full,
    );
  }

  static _CcMixterFile? _parseFile(Map<String, dynamic> json) {
    final url = safeHttpUrl(json['download_url']);
    final format = mapValue(json['file_format_info']);
    final mimeType = stringValue(format?['mime_type']).toLowerCase();
    final extension = stringValue(format?['default-ext']).toLowerCase();
    final isAudio = mimeType.startsWith('audio/') ||
        const {'mp3', 'flac', 'ogg', 'wav', 'm4a'}.contains(extension);
    if (url == null || !isAudio) {
      return null;
    }

    return _CcMixterFile(
      url: url,
      duration: durationFrom(format?['ps']),
    );
  }
}

class _CcMixterFile {
  const _CcMixterFile({required this.url, required this.duration});

  final String url;
  final Duration duration;
}

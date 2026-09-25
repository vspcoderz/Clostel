import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/track.dart';
import '../services/music_catalog.dart';
import 'catalog_utils.dart';

class InternetArchiveMusicCatalog implements MusicCatalog {
  const InternetArchiveMusicCatalog({this.maxItems = 12});

  final int maxItems;

  @override
  Future<List<Track>> getFeatured() => _get('');

  @override
  Future<List<Track>> search(String query) => _get(query);

  Future<List<Track>> _get(String query) async {
    final searchUri = Uri.https('archive.org', '/advancedsearch.php', {
      'q': _searchQuery(query),
      'rows': '${maxItems.clamp(1, 30)}',
      'page': '1',
      'output': 'json',
    });
    final response = await http
        .get(
          searchUri,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'Clostel/0.1 (music catalog client)',
          },
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError('Internet Archive returned HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    final responseBody = mapValue(mapValue(decoded)?['response']);
    final docs = responseBody?['docs'];
    if (docs is! List) {
      throw const FormatException(
        'Internet Archive returned an unexpected catalog shape.',
      );
    }

    final tracks = <Track>[];
    var hasRequestedMetadata = false;
    for (final value in docs.take(maxItems)) {
      final doc = mapValue(value);
      final identifier = stringValue(doc?['identifier']);
      if (identifier.isEmpty) {
        continue;
      }

      try {
        if (hasRequestedMetadata) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        hasRequestedMetadata = true;
        final metadata = await _metadata(identifier);
        final track = parseTrack(metadata, identifier: identifier);
        if (track != null) {
          tracks.add(track);
        }
      } catch (_) {
        // One restricted or temporarily unavailable item should not hide the rest.
      }
    }
    return List<Track>.unmodifiable(tracks);
  }

  Future<Map<String, dynamic>> _metadata(String identifier) async {
    final response = await http
        .get(
          Uri.https('archive.org', '/metadata/$identifier'),
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'Clostel/0.1 (music catalog client)',
          },
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError(
        'Internet Archive metadata returned HTTP ${response.statusCode}.',
      );
    }
    final decoded = jsonDecode(response.body);
    final metadata = mapValue(decoded);
    if (metadata == null) {
      throw const FormatException(
        'Internet Archive metadata returned an unexpected shape.',
      );
    }
    return metadata;
  }

  static Track? parseTrack(
    Map<String, dynamic> json, {
    String? identifier,
  }) {
    final metadata = mapValue(json['metadata']) ?? json;
    final itemIdentifier = stringValue(metadata['identifier']).isNotEmpty
        ? stringValue(metadata['identifier'])
        : stringValue(identifier);
    final files = json['files'];
    if (itemIdentifier.isEmpty || files is! List) {
      return null;
    }

    _ArchiveFile? selected;
    for (final value in files.whereType<Map>()) {
      final file = _parseFile(
        Map<String, dynamic>.from(value),
        identifier: itemIdentifier,
      );
      if (file != null) {
        selected = file;
        break;
      }
    }
    if (selected == null) {
      return null;
    }

    final title = _firstValue(metadata['title']);
    final creator = _firstValue(metadata['creator']);
    final rights = _firstValue(metadata['rights']);
    final licenseUrl = safeHttpUrl(metadata['licenseurl']);
    final duration = durationFrom(metadata['runtime']);
    if (rights.isEmpty && licenseUrl == null) {
      return null;
    }

    return Track(
      id: 'archive-$itemIdentifier',
      title: title.isEmpty ? itemIdentifier : title,
      artist: creator.isEmpty ? 'Internet Archive contributor' : creator,
      album: 'Internet Archive',
      genre: 'Archival audio',
      duration: duration,
      accentValue: accentFor(itemIdentifier),
      streamUrl: selected.url,
      source: 'Internet Archive',
      sourceUrl: 'https://archive.org/details/$itemIdentifier',
      licenseUrl: licenseUrl,
      licenseName: rights.isEmpty ? null : rights,
      attribution: creator.isEmpty
          ? 'Source: Internet Archive item $itemIdentifier.'
          : 'Creator: $creator. Source: Internet Archive item $itemIdentifier.',
      playbackKind: PlaybackKind.full,
    );
  }

  static _ArchiveFile? _parseFile(
    Map<String, dynamic> json, {
    required String identifier,
  }) {
    if (json['private'] == true || stringValue(json['private']) == 'true') {
      return null;
    }

    final name = stringValue(json['name']);
    final format = stringValue(json['format']).toLowerCase();
    final isAudio = format.contains('mp3') ||
        format.contains('flac') ||
        format.contains('ogg') ||
        format.contains('wav') ||
        format.endsWith('m4a');
    if (name.isEmpty || !isAudio) {
      return null;
    }

    final encodedPath = name
        .split('/')
        .map(Uri.encodeComponent)
        .join('/');
    return _ArchiveFile(
      url: 'https://archive.org/download/${Uri.encodeComponent(identifier)}/$encodedPath',
    );
  }

  static String _firstValue(Object? value) {
    if (value is List) {
      return value.whereType<String>().join(', ');
    }
    return stringValue(value);
  }

  static String _searchQuery(String query) {
    final normalized = query
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return 'mediatype:audio AND (title:music OR subject:music)';
    }
    final bounded = normalized.length > 120
        ? normalized.substring(0, 120)
        : normalized;
    return 'mediatype:audio AND (title:"$bounded" OR subject:"$bounded")';
  }
}

class _ArchiveFile {
  const _ArchiveFile({required this.url});

  final String url;
}

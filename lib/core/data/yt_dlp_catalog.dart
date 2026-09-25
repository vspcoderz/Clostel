import 'dart:convert';

import '../models/track.dart';
import '../services/music_catalog.dart';
import '../services/yt_dlp_runner.dart';
import 'catalog_utils.dart';

class YtDlpMusicCatalog implements MusicCatalog {
  const YtDlpMusicCatalog({required this.runner, this.limit = 20});

  final YtDlpRunner runner;
  final int limit;

  @override
  Future<List<Track>> getFeatured() => _search('music');

  @override
  Future<List<Track>> search(String query) {
    final normalized = query.trim();
    return _search(normalized.isEmpty ? 'music' : normalized);
  }

  Future<List<Track>> _search(String query) async {
    final result = await runner.run([
      '--ignore-config',
      '--no-update',
      '--flat-playlist',
      '--dump-single-json',
      '--skip-download',
      '--no-warnings',
      'ytsearch${limit.clamp(1, 50)}:$query',
    ]);
    if (result.exitCode != 0) {
      throw StateError(
        'yt-dlp exited with status ${result.exitCode}: '
        '${result.stderr.toString().trim()}',
      );
    }

    final decoded = jsonDecode(result.stdout);
    if (decoded is! Map || decoded['entries'] is! List) {
      throw const FormatException('yt-dlp returned an unexpected shape.');
    }
    return (decoded['entries'] as List)
        .whereType<Map>()
        .map((entry) => parseTrack(Map<String, dynamic>.from(entry)))
        .whereType<Track>()
        .toList(growable: false);
  }

  static Track? parseTrack(Map<String, dynamic> json) {
    final id = stringValue(json['id']);
    final title = stringValue(json['title']);
    final sourceUrl = safeHttpUrl(
      json['webpage_url'] ?? json['original_url'] ?? json['url'],
    );
    if (id.isEmpty || title.isEmpty || sourceUrl == null) {
      return null;
    }

    final artist = stringValue(json['uploader']).isNotEmpty
        ? stringValue(json['uploader'])
        : stringValue(json['channel']);
    final thumbnails = json['thumbnails'];
    String? artworkUrl;
    if (thumbnails is List) {
      for (final value in thumbnails.reversed) {
        final thumbnail = mapValue(value);
        artworkUrl = safeHttpUrl(thumbnail?['url']);
        if (artworkUrl != null) {
          break;
        }
      }
    }

    return Track(
      id: 'yt-dlp-$id',
      title: title,
      artist: artist.isEmpty ? 'YouTube' : artist,
      album: 'YouTube search',
      genre: 'YouTube',
      duration: durationFrom(json['duration']),
      accentValue: accentFor(id),
      artworkUrl: artworkUrl,
      source: 'yt-dlp',
      sourceUrl: sourceUrl,
      attribution: 'Resolved with yt-dlp. Verify the source rights before use.',
      playbackKind: PlaybackKind.full,
    );
  }
}

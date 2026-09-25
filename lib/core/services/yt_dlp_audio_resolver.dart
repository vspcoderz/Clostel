import 'dart:io';

import '../models/track.dart';
import 'track_file_resolver.dart';
import 'yt_dlp_runner.dart';

class YtDlpAudioResolver implements TrackFileResolver {
  YtDlpAudioResolver({required this.runner});

  final YtDlpRunner runner;
  Directory? _temporaryDirectory;

  @override
  bool supports(Track track) => track.source == 'yt-dlp';

  @override
  Future<String> resolve(Track track) async {
    if (track.source != 'yt-dlp') {
      throw StateError('Track ${track.id} is not a yt-dlp track.');
    }

    final sourceUrl = track.sourceUrl;
    final sourceUri = sourceUrl == null ? null : Uri.tryParse(sourceUrl);
    if (sourceUri == null || !_isYouTubeHost(sourceUri.host)) {
      throw StateError('yt-dlp can only resolve YouTube URLs.');
    }

    final directory = _temporaryDirectory ??=
        await Directory.systemTemp.createTemp('clostel-yt-dlp-');
    final rootPath = '${directory.path}${Platform.pathSeparator}';
    final safeId = track.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final outputTemplate =
        '${directory.path}${Platform.pathSeparator}$safeId.%(ext)s';
    for (final entity in directory.listSync()) {
      if (entity is File && entity.path.startsWith('$rootPath$safeId.')) {
        await entity.delete();
      }
    }
    final result = await runner.run([
      '--ignore-config',
      '--no-update',
      '--no-playlist',
      '--no-warnings',
      '--no-progress',
      '--no-cache-dir',
      '--max-filesize',
      '50M',
      '--extract-audio',
      '--audio-format',
      'mp3',
      '--print',
      'after_move:filepath',
      '--output',
      outputTemplate,
      sourceUri.toString(),
    ]);
    if (result.exitCode != 0) {
      throw StateError(
        'yt-dlp could not prepare ${track.id}: '
        '${result.stderr.toString().trim()}',
      );
    }

    final paths = result.stdout
        .toString()
        .split(RegExp(r'[\r\n]+'))
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .map(File.new);
    for (final file in paths) {
      if (!file.path.startsWith(rootPath) || !await file.exists()) {
        continue;
      }
      return file.path;
    }
    throw StateError('yt-dlp did not return a playable file for ${track.id}.');
  }

  @override
  Future<void> dispose() async {
    final directory = _temporaryDirectory;
    _temporaryDirectory = null;
    if (directory != null && await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  bool _isYouTubeHost(String host) {
    final normalized = host.toLowerCase();
    return normalized == 'youtu.be' ||
        normalized == 'youtube.com' ||
        normalized.endsWith('.youtube.com');
  }
}

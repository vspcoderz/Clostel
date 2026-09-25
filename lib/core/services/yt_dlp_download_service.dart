import 'dart:convert';
import 'dart:io';

import '../models/track.dart';
import 'music_download_service.dart';
import 'yt_dlp_runner.dart';

const _defaultMaxDownloadBytes = 50 * 1024 * 1024;

class YtDlpMusicDownloadService implements MusicDownloadService {
  YtDlpMusicDownloadService({
    required this.runner,
    Directory? downloadsDirectory,
    this.maxFileSizeBytes = _defaultMaxDownloadBytes,
  })  : assert(maxFileSizeBytes > 0),
        _downloadsDirectory = downloadsDirectory;

  final YtDlpRunner runner;
  final int maxFileSizeBytes;
  final Directory? _downloadsDirectory;

  @override
  bool supports(Track track) {
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      return false;
    }
    return track.source == 'yt-dlp' && _isYouTubeTrackUrl(track.sourceUrl);
  }

  @override
  Future<String> download(Track track) async {
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      throw UnsupportedError(
        'Music downloads are supported only on Linux, macOS, and Windows.',
      );
    }
    if (track.source != 'yt-dlp') {
      throw UnsupportedError('Only tracks from yt-dlp can be downloaded.');
    }
    if (!_isYouTubeTrackUrl(track.sourceUrl)) {
      throw const FormatException('yt-dlp can only download YouTube URLs.');
    }

    final directory = _downloadsDirectory ?? await _defaultDownloadsDirectory();
    await directory.create(recursive: true);
    final root = await directory.resolveSymbolicLinks();
    final file = await _unusedOutputFile(directory, track);
    final outputTemplate =
        '${directory.absolute.path}${Platform.pathSeparator}${file.uri.pathSegments.last}';

    final result = await runner.run([
      '--ignore-config',
      '--no-update',
      '--no-playlist',
      '--no-warnings',
      '--no-progress',
      '--no-cache-dir',
      '--max-filesize',
      _maxFilesizeArgument(),
      '--extract-audio',
      '--audio-format',
      'mp3',
      '--audio-quality',
      '192K',
      '--embed-metadata',
      '--embed-thumbnail',
      '--print',
      'after_move:filepath',
      '--output',
      outputTemplate,
      track.sourceUrl!,
    ]);
    if (result.exitCode != 0) {
      final details = result.stderr.toString().trim();
      throw StateError(
        'yt-dlp could not download ${track.id}'
        '${details.isEmpty ? '.' : ': $details'}',
      );
    }

    final reportedPaths = result.stdout
        .toString()
        .split(RegExp(r'[\r\n]+'))
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    if (reportedPaths.length != 1) {
      await _deleteIfPresent(file);
      throw StateError('yt-dlp did not return exactly one download path.');
    }

    final reportedFile = File(reportedPaths.single);
    if (!_samePath(reportedFile.path, file.path) ||
        !await _isDirectChild(reportedFile, root)) {
      await _deleteIfPresent(file);
      throw StateError('yt-dlp returned an unsafe download path.');
    }
    if (!await file.exists()) {
      throw StateError('yt-dlp did not create the expected download.');
    }
    final type = await FileSystemEntity.type(file.path);
    if (type != FileSystemEntityType.file) {
      await _deleteIfPresent(file);
      throw StateError('The download is not a regular file.');
    }

    final size = await file.length();
    if (size > maxFileSizeBytes) {
      await _deleteIfPresent(file);
      throw StateError(
          'The download exceeds the $maxFileSizeBytes byte limit.');
    }
    return file.absolute.path;
  }

  static String sanitizeFileName(String value) {
    var sanitized = value
        .replaceAll(RegExp(r'[\x00-\x1f\x7f-\x9f<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    while (sanitized.startsWith('.') || sanitized.startsWith(' ')) {
      sanitized = sanitized.substring(1).trimLeft();
    }
    while (sanitized.endsWith('.') || sanitized.endsWith(' ')) {
      sanitized = sanitized.substring(0, sanitized.length - 1).trimRight();
    }
    if (_windowsReservedName.hasMatch(sanitized.split('.').first)) {
      sanitized = '_$sanitized';
    }
    if (sanitized.isEmpty) {
      sanitized = 'download';
    }
    if (sanitized.runes.length > 100) {
      sanitized = String.fromCharCodes(sanitized.runes.take(100)).trimRight();
    }
    return sanitized;
  }

  static String buildFileName(Track track) {
    final title = sanitizeFileName(track.title);
    final artist = sanitizeFileName(track.artist);
    final id = sanitizeFileName(track.id);
    final description =
        artist.isEmpty || artist == 'download' ? title : '$artist - $title';
    final stem = _truncateToBytes('$description [$id]', 200).trimRight();
    return '$stem.mp3';
  }

  static String _truncateToBytes(String value, int maximumBytes) {
    final bytes = utf8.encode(value);
    if (bytes.length <= maximumBytes) {
      return value;
    }
    var end = value.length;
    while (
        end > 0 && utf8.encode(value.substring(0, end)).length > maximumBytes) {
      end -= 1;
    }
    return value.substring(0, end);
  }

  static bool _isYouTubeTrackUrl(String? value) {
    if (value == null) {
      return false;
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        (uri.hasPort && uri.port != 443) ||
        uri.userInfo.isNotEmpty ||
        uri.host.isEmpty) {
      return false;
    }

    final host = uri.host.toLowerCase();
    final path = uri.path.replaceAll(RegExp(r'/+'), '/');
    if (host == 'youtu.be') {
      return path != '/' && path.length > 1;
    }
    if (host != 'youtube.com' && !host.endsWith('.youtube.com')) {
      return false;
    }
    return path != '/' && path.length > 1;
  }

  Future<Directory> _defaultDownloadsDirectory() async {
    final home = Platform.environment['HOME']?.trim() ?? '';
    final userProfile = Platform.environment['USERPROFILE']?.trim() ?? '';
    final appData = Platform.environment['APPDATA']?.trim() ?? '';
    final xdgDataHome = Platform.environment['XDG_DATA_HOME']?.trim() ?? '';

    Directory? applicationData;
    if (Platform.isWindows && Directory(appData).isAbsolute) {
      applicationData = Directory(appData);
    } else if (Platform.isWindows && Directory(userProfile).isAbsolute) {
      applicationData = Directory(
        '$userProfile${Platform.pathSeparator}AppData'
        '${Platform.pathSeparator}Roaming',
      );
    } else if (Platform.isMacOS && Directory(home).isAbsolute) {
      applicationData = Directory(
        '$home${Platform.pathSeparator}Library'
        '${Platform.pathSeparator}Application Support',
      );
    } else if (Platform.isLinux && Directory(xdgDataHome).isAbsolute) {
      applicationData = Directory(xdgDataHome);
    } else if (Platform.isLinux && Directory(home).isAbsolute) {
      applicationData = Directory(
        '$home${Platform.pathSeparator}.local${Platform.pathSeparator}share',
      );
    }
    if (applicationData == null) {
      throw StateError(
          'Could not determine the user application-data directory.');
    }
    return Directory(
      '${applicationData.absolute.path}${Platform.pathSeparator}Clostel'
      '${Platform.pathSeparator}downloads',
    );
  }

  Future<File> _unusedOutputFile(Directory directory, Track track) async {
    final baseName = buildFileName(track);
    final extensionIndex = baseName.lastIndexOf('.');
    final stem = baseName.substring(0, extensionIndex);
    final extension = baseName.substring(extensionIndex);
    var candidate = File(
      '${directory.absolute.path}${Platform.pathSeparator}$baseName',
    );
    var suffix = 2;
    while (await candidate.exists()) {
      candidate = File(
        '${directory.absolute.path}${Platform.pathSeparator}$stem ($suffix)$extension',
      );
      suffix += 1;
    }
    return candidate;
  }

  String _maxFilesizeArgument() {
    const unit = 1024 * 1024;
    final wholeMegabytes = maxFileSizeBytes ~/ unit;
    if (wholeMegabytes > 0 && wholeMegabytes * unit == maxFileSizeBytes) {
      return '${wholeMegabytes}M';
    }
    return '${maxFileSizeBytes}B';
  }

  Future<bool> _isDirectChild(File file, String canonicalRoot) async {
    if (!file.isAbsolute) {
      return false;
    }
    try {
      final canonicalFile = await file.resolveSymbolicLinks();
      final parent = File(canonicalFile).parent.absolute.path;
      return _samePath(parent, canonicalRoot);
    } on FileSystemException {
      return false;
    }
  }

  bool _samePath(String first, String second) {
    String normalize(String path) {
      final normalized = path
          .replaceAll('\\', '/')
          .replaceAll(RegExp(r'/+'), '/')
          .replaceFirst(RegExp(r'/$'), '');
      return Platform.isWindows ? normalized.toLowerCase() : normalized;
    }

    return normalize(File(first).absolute.path) ==
        normalize(File(second).absolute.path);
  }

  Future<void> _deleteIfPresent(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  static final _windowsReservedName = RegExp(
    r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])$',
    caseSensitive: false,
  );
}

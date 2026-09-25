import 'dart:io';

import 'package:clostel/core/models/track.dart';
import 'package:clostel/core/services/yt_dlp_download_service.dart';
import 'package:clostel/core/services/yt_dlp_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YtDlpMusicDownloadService', () {
    late Directory temporaryDirectory;
    late Directory downloadsDirectory;

    setUp(() async {
      temporaryDirectory = await Directory.systemTemp.createTemp(
        'clostel-download-test-',
      );
      downloadsDirectory = Directory(
        '${temporaryDirectory.path}${Platform.pathSeparator}downloads',
      );
    });

    tearDown(() async {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    });

    test('uses a sanitized output path and ffmpeg-compatible MP3 flags',
        () async {
      late List<String> arguments;
      final runner = _FakeYtDlpRunner((received) async {
        arguments = received;
        final output = File(received[received.indexOf('--output') + 1]);
        await output.writeAsBytes(<int>[1, 2, 3]);
        return ProcessResult(1, 0, '${output.path}\n', '');
      });
      final service = YtDlpMusicDownloadService(
        runner: runner,
        downloadsDirectory: downloadsDirectory,
      );
      final track = _youtubeTrack(
        id: 'yt/dlp?unsafe',
        title: '../Bad / Name: *?',
        artist: 'Artist<>',
        sourceUrl: 'https://www.youtube.com/watch?v=abc123',
      );

      final path = await service.download(track);

      expect(path, startsWith(downloadsDirectory.absolute.path));
      expect(File(path).parent.path, downloadsDirectory.absolute.path);
      expect(File(path).uri.pathSegments.last, isNot(contains('/')));
      expect(File(path).uri.pathSegments.last, isNot(contains(r'\')));
      expect(File(path).uri.pathSegments.last, isNot(contains('..')));
      expect(File(path).uri.pathSegments.last, endsWith('.mp3'));
      expect(arguments, containsAllInOrder(<String>['--max-filesize', '50M']));
      expect(arguments, containsAllInOrder(<String>['--extract-audio']));
      expect(arguments, containsAllInOrder(<String>['--audio-format', 'mp3']));
      expect(arguments, containsAllInOrder(<String>['--embed-metadata']));
      expect(arguments, containsAllInOrder(<String>['--embed-thumbnail']));
      expect(arguments.last, track.sourceUrl);
      expect(
        arguments.where(
          (argument) => RegExp(
            r'cookie|token|bypass|age.restrict',
            caseSensitive: false,
          ).hasMatch(argument),
        ),
        isEmpty,
      );
    });

    test('rejects unsupported tracks and non-YouTube URLs', () async {
      final runner = _FakeYtDlpRunner((arguments) async {
        fail('yt-dlp must not run for an unsupported track.');
      });
      final service = YtDlpMusicDownloadService(
        runner: runner,
        downloadsDirectory: downloadsDirectory,
      );
      final otherSource = _youtubeTrack(
        source: 'Jamendo',
        sourceUrl: 'https://www.youtube.com/watch?v=abc123',
      );
      final otherHost = _youtubeTrack(
        sourceUrl: 'https://youtube.com.example.test/watch?v=abc123',
      );

      expect(service.supports(otherSource), isFalse);
      await expectLater(
        service.download(otherSource),
        throwsA(isA<UnsupportedError>()),
      );
      expect(service.supports(otherHost), isFalse);
      await expectLater(
        service.download(otherHost),
        throwsA(isA<FormatException>()),
      );
      expect(runner.calls, 0);
    });

    test('rejects a response path outside the downloads directory', () async {
      final outside = File(
        '${temporaryDirectory.path}${Platform.pathSeparator}outside.mp3',
      );
      final runner = _FakeYtDlpRunner((arguments) async {
        await outside.writeAsBytes(<int>[1, 2, 3]);
        return ProcessResult(1, 0, outside.path, '');
      });
      final service = YtDlpMusicDownloadService(
        runner: runner,
        downloadsDirectory: downloadsDirectory,
      );

      await expectLater(
        service.download(_youtubeTrack()),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('unsafe download path'),
          ),
        ),
      );
    });

    test('removes a response that exceeds the configured file-size cap',
        () async {
      late File output;
      final runner = _FakeYtDlpRunner((arguments) async {
        output = File(arguments[arguments.indexOf('--output') + 1]);
        await output.writeAsBytes(<int>[1, 2, 3, 4, 5]);
        return ProcessResult(1, 0, output.path, '');
      });
      final service = YtDlpMusicDownloadService(
        runner: runner,
        downloadsDirectory: downloadsDirectory,
        maxFileSizeBytes: 4,
      );

      await expectLater(
        service.download(_youtubeTrack()),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('byte limit'),
          ),
        ),
      );
      expect(await output.exists(), isFalse);
    });
  });
}

Track _youtubeTrack({
  String id = 'yt-dlp-abc123',
  String title = 'Track title',
  String artist = 'Track artist',
  String source = 'yt-dlp',
  String? sourceUrl = 'https://youtu.be/abc123',
}) {
  return Track(
    id: id,
    title: title,
    artist: artist,
    album: 'YouTube search',
    genre: 'YouTube',
    duration: const Duration(minutes: 3),
    accentValue: 0xFF000000,
    source: source,
    sourceUrl: sourceUrl,
  );
}

class _FakeYtDlpRunner implements YtDlpRunner {
  _FakeYtDlpRunner(this._onRun);

  final Future<ProcessResult> Function(List<String> arguments) _onRun;
  int calls = 0;

  @override
  Future<ProcessResult> run(List<String> arguments) {
    calls += 1;
    return _onRun(arguments);
  }
}

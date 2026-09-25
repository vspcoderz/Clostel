import 'dart:async';
import 'dart:convert';
import 'dart:io';

abstract interface class YtDlpRunner {
  Future<ProcessResult> run(List<String> arguments);
}

class ProcessYtDlpRunner implements YtDlpRunner {
  const ProcessYtDlpRunner({
    required this.executable,
    this.timeout = const Duration(minutes: 5),
  });

  final String executable;
  final Duration timeout;

  @override
  Future<ProcessResult> run(List<String> arguments) async {
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      throw UnsupportedError(
        'yt-dlp is supported only on Linux, macOS, and Windows.',
      );
    }

    final process = await Process.start(
      executable,
      arguments,
      runInShell: false,
    );
    final stdout = process.stdout.transform(utf8.decoder).join();
    final stderr = process.stderr.transform(utf8.decoder).join();
    var exitCode = -1;
    try {
      exitCode = await process.exitCode.timeout(timeout);
    } on TimeoutException {
      process.kill();
    }
    return ProcessResult(
      process.pid,
      exitCode,
      await stdout,
      await stderr,
    );
  }
}

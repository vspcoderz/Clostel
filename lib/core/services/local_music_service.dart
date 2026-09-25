import 'package:file_picker/file_picker.dart';

import '../models/track.dart';

class LocalMusicService {
  const LocalMusicService();

  Future<List<Track>> pickAudioFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );
    if (result == null) {
      return const [];
    }

    return result.files
        .where((file) => file.path != null)
        .map(_trackFromPath)
        .toList(growable: false);
  }

  Track _trackFromPath(PlatformFile file) {
    final path = file.path!;
    final fileName = path.split(RegExp(r'[/\\]')).last;
    final title = _titleFromFileName(fileName);
    return Track(
      id: 'local-$path',
      title: title,
      artist: 'Local file',
      album: 'Offline library',
      genre: 'Imported audio',
      duration: Duration.zero,
      accentValue: _accentValues[path.hashCode.abs() % _accentValues.length],
      filePath: path,
      source: 'Local file',
    );
  }

  String _titleFromFileName(String fileName) {
    final extensionIndex = fileName.lastIndexOf('.');
    final baseName =
        extensionIndex > 0 ? fileName.substring(0, extensionIndex) : fileName;
    return baseName.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  }

  static const _accentValues = [
    0xFFEB5E55,
    0xFFD81E5B,
    0xFFC6D8D3,
    0xFFFDF0D5,
    0xFF3A3335,
  ];
}

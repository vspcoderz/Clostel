class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.duration,
    required this.accentValue,
    this.assetPath,
    this.streamUrl,
    this.filePath,
    this.artworkUrl,
    this.source,
    this.licenseUrl,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final Duration duration;
  final int accentValue;
  final String? assetPath;
  final String? streamUrl;
  final String? filePath;
  final String? artworkUrl;
  final String? source;
  final String? licenseUrl;

  bool get isPreview => source == 'Deezer';

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return [title, artist, album, genre]
        .any((value) => value.toLowerCase().contains(normalized));
  }
}

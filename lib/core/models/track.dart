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
    this.artworkUrl,
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
  final String? artworkUrl;

  bool get isPreview => streamUrl != null;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return [title, artist, album, genre]
        .any((value) => value.toLowerCase().contains(normalized));
  }
}

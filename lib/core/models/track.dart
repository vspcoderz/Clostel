enum PlaybackKind {
  full,
  preview,
  unknown,
}

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
    this.sourceUrl,
    this.licenseUrl,
    this.licenseName,
    this.attribution,
    this.playbackKind = PlaybackKind.full,
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
  final String? sourceUrl;
  final String? licenseUrl;
  final String? licenseName;
  final String? attribution;
  final PlaybackKind playbackKind;

  bool get isPreview => playbackKind == PlaybackKind.preview;

  bool get hasVerifiedPlayback => playbackKind != PlaybackKind.unknown;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return [title, artist, album, genre]
        .any((value) => value.toLowerCase().contains(normalized));
  }
}

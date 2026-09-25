import 'package:flutter_test/flutter_test.dart';

import 'package:clostel/core/data/audius_catalog.dart';
import 'package:clostel/core/data/ccmixter_catalog.dart';
import 'package:clostel/core/data/internet_archive_catalog.dart';
import 'package:clostel/core/data/itunes_catalog.dart';
import 'package:clostel/core/data/openverse_catalog.dart';
import 'package:clostel/core/data/yt_dlp_catalog.dart';
import 'package:clostel/core/data/music_catalog_chain.dart';
import 'package:clostel/core/models/track.dart';
import 'package:clostel/core/services/music_catalog.dart';

void main() {
  test('normalizes a ccMixter full track with attribution and license', () {
    final track = CcMixterMusicCatalog.parseTrack({
      'upload_id': 42,
      'upload_name': 'Open Sky',
      'user_name': 'artist',
      'user_real_name': 'A. Artist',
      'license_name': 'Attribution (4.0)',
      'license_url': 'https://creativecommons.org/licenses/by/4.0/',
      'file_page_url': 'https://ccmixter.org/files/artist/42',
      'upload_extra': {
        'usertags': 'ambient,instrumental',
      },
      'files': [
        {
          'download_url': 'https://ccmixter.org/content/artist/open-sky.mp3',
          'file_format_info': {
            'mime_type': 'audio/mpeg',
            'default-ext': 'mp3',
            'ps': '3:12',
          },
        },
      ],
    });

    expect(track, isNotNull);
    expect(track!.id, 'ccmixter-42');
    expect(track.artist, 'A. Artist');
    expect(track.genre, 'ambient');
    expect(track.duration, const Duration(minutes: 3, seconds: 12));
    expect(track.licenseUrl, contains('creativecommons.org'));
    expect(track.playbackKind, PlaybackKind.full);
  });

  test('rejects ccMixter rows without a safe audio file', () {
    final track = CcMixterMusicCatalog.parseTrack({
      'upload_id': 42,
      'upload_name': 'Open Sky',
      'user_name': 'artist',
      'files': [
        {
          'download_url': 'file:///tmp/open-sky.mp3',
          'file_format_info': {'mime_type': 'audio/mpeg'},
        },
      ],
    });

    expect(track, isNull);
  });

  test('normalizes an Openverse result and preserves provider uncertainty', () {
    final track = OpenverseMusicCatalog.parseTrack({
      'id': 'audio-1',
      'title': 'Night Walk',
      'creator': 'A. Artist',
      'url': 'https://cdn.example.test/night-walk.mp3',
      'foreign_landing_url': 'https://source.example.test/track/1',
      'license': 'by',
      'license_version': '4.0',
      'license_url': 'https://creativecommons.org/licenses/by/4.0/',
      'provider': 'example',
      'category': 'music',
      'duration': 125000,
      'attribution': 'A. Artist, CC BY 4.0',
    });

    expect(track, isNotNull);
    expect(track!.duration, const Duration(milliseconds: 125000));
    expect(track.licenseName, 'by 4.0');
    expect(track.playbackKind, PlaybackKind.unknown);
    expect(track.sourceUrl, contains('source.example.test'));
  });

  test('normalizes a public Internet Archive audio file', () {
    final track = InternetArchiveMusicCatalog.parseTrack({
      'metadata': {
        'identifier': 'field-recording',
        'title': 'Field Recording',
        'creator': 'Archive contributor',
        'rights': 'CC0 1.0',
        'licenseurl': 'https://creativecommons.org/publicdomain/zero/1.0/',
        'runtime': '1:05',
      },
      'files': [
        {
          'name': 'field recording.mp3',
          'format': 'VBR MP3',
          'private': 'false',
        },
      ],
    });

    expect(track, isNotNull);
    expect(track!.id, 'archive-field-recording');
    expect(track.streamUrl, contains('/download/field-recording/'));
    expect(track.licenseName, 'CC0 1.0');
  });

  test('normalizes an iTunes promotional preview', () {
    final track = ITunesMusicCatalog.parseTrack({
      'trackId': 123,
      'trackName': 'Store Preview',
      'artistName': 'A. Artist',
      'collectionName': 'Album',
      'primaryGenreName': 'Pop',
      'trackTimeMillis': 30000,
      'previewUrl': 'https://audio.example.test/preview.m4a',
      'artworkUrl100': 'https://images.example.test/100x100bb.jpg',
      'trackViewUrl': 'https://music.apple.com/us/album/123',
    });

    expect(track, isNotNull);
    expect(track!.id, 'itunes-123');
    expect(track.streamUrl, contains('preview.m4a'));
    expect(track.sourceUrl, contains('music.apple.com'));
    expect(track.playbackKind, PlaybackKind.preview);
  });

  test('normalizes an Audius track and its stream URL', () {
    final track = AudiusMusicCatalog.parseTrack({
      'id': 'abc',
      'title': 'Open Track',
      'user': {'name': 'A. Artist'},
      'duration': 180,
      'stream': {
        'url': 'https://stream.example.test/abc.mp3',
      },
      'artwork': {
        '1000x1000': 'https://images.example.test/abc.jpg',
      },
      'permalink': '/artist/open-track',
      'license': 'Open Music License',
    });

    expect(track, isNotNull);
    expect(track!.id, 'audius-abc');
    expect(track.streamUrl, contains('abc.mp3'));
    expect(track.artworkUrl, contains('abc.jpg'));
    expect(track.sourceUrl, contains('audius.co/artist/open-track'));
    expect(track.playbackKind, PlaybackKind.full);
  });

  test('keeps later catalog sources reachable when merging results', () async {
    final chain = MusicCatalogChain(
      sources: [
        _FakeCatalog([_track('first')]),
        _FakeCatalog([_track('second')]),
      ],
      maxResults: 2,
      perSourceLimit: 1,
    );

    final tracks = await chain.getFeatured();

    expect(tracks.map((track) => track.id), equals(['first', 'second']));
  });

  test('normalizes a yt-dlp search result for the opt-in resolver', () {
    final track = YtDlpMusicCatalog.parseTrack({
      'id': 'video-1',
      'title': 'A Song',
      'uploader': 'A. Artist',
      'duration': 201,
      'webpage_url': 'https://www.youtube.com/watch?v=video-1',
      'thumbnails': [
        {'url': 'https://i.example.test/low.jpg'},
        {'url': 'https://i.example.test/high.jpg'},
      ],
    });

    expect(track, isNotNull);
    expect(track!.source, 'yt-dlp');
    expect(track.sourceUrl, contains('youtube.com'));
    expect(track.artworkUrl, contains('high.jpg'));
    expect(track.playbackKind, PlaybackKind.full);
  });
}

Track _track(String id) {
  return Track(
    id: id,
    title: id,
    artist: 'Artist',
    album: 'Album',
    genre: 'Music',
    duration: Duration.zero,
    accentValue: 0xFFC6D8D3,
    streamUrl: 'https://example.test/$id.mp3',
  );
}

class _FakeCatalog implements MusicCatalog {
  const _FakeCatalog(this.tracks);

  final List<Track> tracks;

  @override
  Future<List<Track>> getFeatured() async => tracks;

  @override
  Future<List<Track>> search(String query) async => tracks;
}

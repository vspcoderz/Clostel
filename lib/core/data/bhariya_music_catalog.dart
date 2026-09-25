import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/track.dart';
import '../services/music_catalog.dart';
import 'catalog_utils.dart';

/// An opt-in adapter for a separately hosted BhariyaMusic-compatible service.
///
/// The service has no bundled endpoint and this adapter does not provide one.
/// Set the API base URL with `BHARIYA_MUSIC_API_BASE_URL` to enable metadata
/// lookup. Audio is deliberately disabled unless the service is also started
/// with the exact opt-in value `BHARIYA_MUSIC_AUDIO_ENABLED=true`.
///
/// BhariyaMusic responses can point at third-party content whose rights are not
/// established by this adapter. The returned track therefore keeps its source
/// identifiers and labels the rights boundary for the UI to display.
class BhariyaMusicCatalog implements MusicCatalog {
  const BhariyaMusicCatalog({
    required this.apiBaseUrl,
    this.audioEnabled = false,
    this.client,
    this.requestTimeout = const Duration(seconds: 20),
  });

  /// The externally configured service root, for example the host and any
  /// required path prefix. No default or bundled service URL is provided.
  final String apiBaseUrl;

  /// Whether the user explicitly opted in to the experimental audio surface.
  /// This is intentionally a normal boolean in the adapter so callers cannot
  /// accidentally enable audio just by configuring a URL.
  final bool audioEnabled;

  /// Injectable for focused tests. No authentication, cookies, or credentials
  /// are sent by the adapter.
  final http.Client? client;

  final Duration requestTimeout;

  /// A catalog is added to the application chain only when its base URL is a
  /// valid, credential-free HTTP(S) URL.
  bool get isConfigured => _baseUri != null;

  @override
  Future<List<Track>> getFeatured() async => const <Track>[];

  @override
  Future<List<Track>> search(String query) async {
    final normalized = query.trim();
    if (!isConfigured || normalized.isEmpty || normalized.length > 500) {
      return const <Track>[];
    }

    // BhariyaMusic accepts either a search string or a source URL. A value
    // that claims to be a URL must be a valid HTTP(S) URL before it is sent to
    // the service. Plain text remains free-form because the service supports
    // song names as searches.
    if (_looksLikeUrl(normalized) && safeHttpUrl(normalized) == null) {
      return const <Track>[];
    }

    final prepareUri = _endpoint('prepare', normalized);
    final preparedId = parsePreparedId(await _getJson(prepareUri));
    if (preparedId == null) {
      return const <Track>[];
    }

    final fetchUri = _endpoint('fetch', preparedId);
    final response = await _getJson(fetchUri);
    final track = parseFetchResponse(
      response,
      preparedId: preparedId,
      query: normalized,
      audioEnabled: audioEnabled,
      sourceUrl: prepareUri.toString(),
      audioBaseUrl: apiBaseUrl,
    );
    return track == null ? const <Track>[] : <Track>[track];
  }

  Future<Object?> _getJson(Uri uri) async {
    const headers = {
      'Accept': 'application/json',
      'User-Agent': 'Clostel/0.1 (music catalog client)',
    };
    final response = client == null
        ? await http.get(uri, headers: headers).timeout(requestTimeout)
        : await client!.get(uri, headers: headers).timeout(requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('BhariyaMusic returned HTTP ${response.statusCode}.');
    }
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    if (!contentType.contains('application/json')) {
      throw const FormatException(
        'BhariyaMusic returned a non-JSON response.',
      );
    }
    if (response.bodyBytes.length > 256 * 1024) {
      throw const FormatException(
        'BhariyaMusic returned an oversized response.',
      );
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Uri _endpoint(String operation, String value) {
    final base = _baseUri!;
    final segments = <String>[
      ...base.pathSegments.where((segment) => segment.isNotEmpty),
      'api',
      operation,
      value,
    ];
    return base.replace(
      pathSegments: segments,
      query: null,
      fragment: null,
    );
  }

  Uri? get _baseUri => _validatedBaseUri(apiBaseUrl);

  static Uri? _validatedBaseUri(Object? value) {
    final raw = stringValue(value).trim();
    if (raw.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !uri.isAbsolute ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    if (uri.scheme == 'http' && !_isLoopbackHost(uri.host)) {
      return null;
    }
    return uri;
  }

  static bool _isLoopbackHost(String host) {
    final normalized = host.toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '::1';
  }

  /// Accepts the documented `{ "ID": "..." }` prepare response and common
  /// case/wrapper variants, while rejecting values that cannot safely be used
  /// as a fetch path segment.
  static String? parsePreparedId(Object? response) {
    final payload = _payloadMap(response);
    if (payload == null) {
      return null;
    }
    final id = _string(_field(payload, const [
      'ID',
      'id',
      'song_id',
      'songId',
    ]));
    return _isSafeId(id) ? id : null;
  }

  /// Normalizes a fetch response into a metadata-only or opt-in audio track.
  /// The optional URL arguments are supplied by the adapter so static callers
  /// can still parse an already-validated response in tests.
  static Track? parseFetchResponse(
    Object? response, {
    String? preparedId,
    String? query,
    bool audioEnabled = false,
    String? sourceUrl,
    String? audioBaseUrl,
  }) {
    final payload = _payloadMap(response);
    if (payload == null) {
      return null;
    }
    return parseTrack(
      payload,
      preparedId: preparedId,
      query: query,
      audioEnabled: audioEnabled,
      sourceUrl: sourceUrl,
      audioBaseUrl: audioBaseUrl,
    );
  }

  static Track? parseTrack(
    Map<String, dynamic> json, {
    String? preparedId,
    String? query,
    bool audioEnabled = false,
    String? sourceUrl,
    String? audioBaseUrl,
  }) {
    final payload = _payloadMap(json) ?? json;
    final responseId = _string(_field(payload, const [
      'ID',
      'id',
      'song_id',
      'songId',
    ]));
    final id = preparedId != null && _isSafeId(preparedId)
        ? preparedId
        : _isSafeId(responseId)
            ? responseId
            : null;
    if (id == null) {
      return null;
    }

    final title = _string(_field(payload, const [
      'SONG_NAME',
      'songName',
      'song_name',
      'title',
      'name',
    ])).isNotEmpty
        ? _string(_field(payload, const [
            'SONG_NAME',
            'songName',
            'song_name',
            'title',
            'name',
          ]))
        : _string(query);
    if (title.isEmpty) {
      return null;
    }

    final artist = _optionalString(_field(payload, const [
      'ARTIST',
      'artist',
      'artist_name',
      'artistName',
    ]));
    final album = _optionalString(_field(payload, const [
      'ALBUM',
      'album',
      'album_name',
      'albumName',
    ]));
    final genre = _optionalString(_field(payload, const [
      'GENRE',
      'genre',
    ]));
    final duration = _durationFrom(_field(payload, const [
      'DURATION',
      'duration',
      'length',
    ]));
    final artworkUrl = _firstSafeUrl(payload, const [
      'THUMBNAIL',
      'thumbnail',
      'artwork_url',
      'artworkUrl',
    ]);
    final responseSourceUrl = _firstSafeUrl(payload, const [
      'SOURCE_URL',
      'source_url',
      'sourceUrl',
      'original_url',
      'webpage_url',
    ]);

    final validatedSourceUrl = responseSourceUrl;
    final hasAudioBase = _validatedBaseUri(audioBaseUrl) != null;
    final streamUrl = audioEnabled && hasAudioBase
        ? _fallbackAudioUrl(audioBaseUrl ?? '', id)
        : null;
    final playbackKind =
        streamUrl == null ? PlaybackKind.unknown : PlaybackKind.full;

    final youtubeId = _string(_field(payload, const [
      'YT_ID',
      'yt_id',
      'ytId',
      'youtube_id',
      'youtubeId',
    ]));
    final spotifyId = _string(_field(payload, const [
      'SPOTIFY_ID',
      'spotify_id',
      'spotifyId',
    ]));
    final provenance = <String>[
      'BhariyaMusic experimental provider.',
      if (youtubeId.isNotEmpty) 'YouTube ID: $youtubeId.',
      if (spotifyId.isNotEmpty) 'Spotify ID: $spotifyId.',
      'Rights are not verified by Clostel; verify licensing before playback or reuse.',
    ].join(' ');

    return Track(
      id: 'bhariya-$id',
      title: title,
      artist: artist ?? 'Unknown artist',
      album: album ?? 'BhariyaMusic catalog',
      genre: genre ?? 'Experimental music',
      duration: duration,
      accentValue: accentFor(id),
      streamUrl: streamUrl,
      artworkUrl: artworkUrl,
      source: 'BhariyaMusic',
      sourceUrl: validatedSourceUrl,
      licenseName: 'Experimental rights boundary',
      attribution: provenance,
      playbackKind: playbackKind,
    );
  }

  static String? _fallbackAudioUrl(String baseUrl, String id) {
    final base = _validatedBaseUri(baseUrl);
    if (base == null || !_isSafeId(id)) {
      return null;
    }
    final uri = base.replace(
      pathSegments: <String>[
        ...base.pathSegments.where((segment) => segment.isNotEmpty),
        'api',
        'audio',
        id,
      ],
      query: null,
      fragment: null,
    );
    return safeHttpUrl(uri.toString());
  }

  static Map<String, dynamic>? _payloadMap(Object? value) {
    final map = mapValue(value);
    if (map == null) {
      return null;
    }
    for (final key in const ['data', 'song', 'result', 'response']) {
      final nested = mapValue(map[key]);
      if (nested != null) {
        return nested;
      }
    }
    return map;
  }

  static Object? _field(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) {
        return json[key];
      }
    }
    final normalizedKeys = keys.map((key) => key.toLowerCase()).toSet();
    for (final entry in json.entries) {
      if (normalizedKeys.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }

  static String? _firstSafeUrl(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = safeHttpUrl(_field(json, [key]));
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static String? _optionalString(Object? value) {
    final result = _string(value);
    return result.isEmpty ? null : result;
  }

  static String _string(Object? value) => stringValue(value).trim();

  static bool _isSafeId(String value) {
    return value.isNotEmpty &&
        value.length <= 128 &&
        RegExp(r'^[A-Za-z0-9][A-Za-z0-9._~-]*$').hasMatch(value);
  }

  static bool _looksLikeUrl(String value) {
    return RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*://').hasMatch(value);
  }

  static Duration _durationFrom(Object? value) {
    final duration = durationFrom(value);
    return duration.isNegative ? Duration.zero : duration;
  }
}

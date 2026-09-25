# BhariyaMusic integration audit for Clostel

**Research date:** 2026-09-25  
**Audited repository:** `BhaskarPanja93/BhariyaMusic`, local commit `8dfd5f5c67e7228d1ca515db62492ce3ba3fce43` (2026-06-07)  
**Scope:** Static source audit of `/tmp/opencode/BhariyaMusic`. Paths below refer to that repository unless prefixed with `Clostel/`. This is a technical and licensing-risk assessment, not legal advice.

## Verdict

**Do not integrate BhariyaMusic as a Clostel production catalog or playback backend.** It is an unauthenticated, unversioned Python service whose main value is yt-dlp audio extraction, has no repository license, carries no media-rights fields, and explicitly says the audited version may no longer work. Its sole defensible Clostel boundary is an **opt-in, metadata-only experiment** that never exposes `AUDIO_URL`, `/api/audio`, cookies, or server credentials and marks every result `PlaybackKind.unknown`. Even that experiment requires the service operator's permission, documented endpoint terms, and privacy disclosure.

## Architecture

### Service topology

- `MusicAPI_servers.py:1-12` is an auto-restart wrapper that waits for a missing `Hidden.Secrets` file and then delegates process/file checks to an undeclared `autoReRun` dependency.
- `_server.py:1-23` monkey-patches gevent before importing Flask, Jinja, the bundled dynamic-web application, and the resolver stack. `_server.py:93-98` creates the logger, pooled MySQL holder, file cache, URL handler, and in-memory song cache at import time.
- `_server.py:101-135` exposes three unauthenticated GET routes. `_server.py:138-149` serves two JavaScript files. The README places the Flask app behind a reverse-proxy prefix, `/music` (`README.md:20-33,37-41`); the application itself does not mount that prefix.
- `Classes/Processors/WSGIElements.py:19-24` binds gevent WSGI to `0.0.0.0`, with HTTP unless certificate and key paths are explicitly supplied. `_server.py:152-171` derives scheme/path/address from proxy headers and the launcher supplies neither TLS files nor an authentication middleware.
- `Hidden/dynamicWebsite.py:551-600` adds a cookie-based HTML application and WebSocket channel. Its form CSRF protects only that custom form flow (`Hidden/dynamicWebsite.py:338-361,489-510`); it does not protect the REST routes in `_server.py`.

### Resolution pipeline

1. `SongCache.get_song_id` classifies a query as a YouTube track, Spotify track, playlist/artist/album, or free text, then checks aliases and the MySQL cache (`Classes/Processors/URLHandler.py:50-72`; `Classes/Processors/SongProcessor.py:174-196`).
2. A cache miss creates a 30-character random ID and starts resolution in a thread (`Classes/Processors/SongProcessor.py:190-196`). `/api/fetch` blocks on that thread's event rather than returning a pending status (`Classes/Processors/SongProcessor.py:199-215`).
3. yt-dlp resolves either a direct YouTube URL or `<query> lyrics`; one of two extractor instances is tried and all extractor exceptions are discarded (`Classes/Processors/SongProcessor.py:66-90`; `Classes/Processors/YTDLP.py:36-46`). The first yt-dlp instance selects `bestaudio`; both use effectively infinite retries and high retry counts (`Classes/Processors/YTDLP.py:14-31`).
4. Spotipy client credentials enrich the result with a Spotify track ID (`Classes/Processors/SongProcessor.py:92-103`). When resolving a Spotify URL, the implementation obtains track metadata and then searches YouTube for the resulting title (`Classes/Processors/SongProcessor.py:76-81`).
5. The chosen CDN URL is treated as valid for five hours. The service immediately starts downloading the entire audio response into an in-memory chunk list, retains the object for roughly four hours after last use, and persists the CDN URL and refresh timestamp in MySQL (`Classes/Processors/SongProcessor.py:104-109,144-171`; `Classes/Processors/SongData.py:70-83,86-117`).

### Deployment and maintainability state

- The audited commit's own message says Spotify and yt-dlp have changed and the project “will most likely not work at all at this point.” There are no tests, CI files, migrations, version pins, `requirements.txt`, or `pyproject.toml` in the tracked tree.
- `README.md:45-50` claims a YouTube Data API integration, but the code uses yt-dlp and cookies; it does not call the YouTube Data API.
- The sample configuration is incomplete. `FileInvolved.py:1` imports `folderLocation`, and `MusicAPI_servers.py:4-10` imports `RequiredFiles`, but neither exists in `Hidden/Secrets.sample.py:1-15`.
- Several non-standard Python packages are imported but neither bundled nor declared. Deployment would therefore not be reproducible from the repository.
- Linux deployment is currently case-sensitive and incomplete: `Classes/Holders/FileInvolved.py:22` requests `Static/HTML/Index.html`, while the tracked file is `Static/HTML/index.html`; the JavaScript files referenced at `Classes/Holders/FileInvolved.py:27-29` are not tracked.

## API contract

The README advertises these endpoints beneath `https://bhindi1.ddns.net/music` (`README.md:18-33`). The following describes the implementation, not a versioned or stability-guaranteed contract.

| Operation | Request | Success body | Important failure behavior |
|---|---|---|---|
| Prepare | `GET /api/prepare/{query}` | `{"ID":"<30 alphanumeric chars>"}` or `{"ID":null}` | Query rendering/extraction/DB failures become uncaught 500s. The Flask `<string>` route does not naturally accept a URL containing `/`, despite the README's `{song_name/url}` notation. |
| Fetch | `GET /api/fetch/{id}` | Song object below | A missing ID is HTTP 200 with `{"ERROR":"Song not found"}`; preparation/DB failures become 500s. A valid preparation can block indefinitely. |
| Audio | `GET /api/audio/{id}` | Raw generator-backed audio bytes | Missing IDs and upstream failures become 500s. No explicit media type, length, range, cache, or error contract is set. |

Routes and implementations: `_server.py:101-135`. IDs are generated by `RandomisedString().AlphaNumeric(30,30)` (`Classes/Processors/SongProcessor.py:190`).

### Fetch response

`SongData.full_dict` defines the actual body (`Classes/Processors/SongData.py:34-49`):

```json
{
  "ID": "string",
  "SONG_NAME": "string",
  "YT_ID": "youtube-id-or-empty",
  "SPOTIFY_ID": "string-or-empty",
  "DURATION": 0,
  "AUDIO_URL": "ephemeral-cdn-url",
  "THUMBNAIL": "url-or-null",
  "EXPIRY": "datetime-serialized-by-Flask",
  "LYRICS": "placeholder-or-string"
}
```

Clostel must treat all values as optional/untrusted despite the example. The implementation can emit missing/null duration or thumbnail values and an empty Spotify ID; it does not define nullability, maximum lengths, date format, error codes, or schema version. `SONG_NAME` is not separated into title and artist, and there are no album, genre, rights, license, attribution, content owner, or takedown fields.

Other contract gaps:

- No API version, authentication, authorization, CORS policy, rate limit, quota, pagination, idempotency key, or health/readiness endpoint.
- `prepare` starts work before the client can demonstrate permission or intent; every anonymous request can trigger database writes, YouTube extraction, Spotify calls, and audio download.
- `fetch` exposes the CDN URL but only refreshes it as a side effect of fetching (`Classes/Processors/SongProcessor.py:112-141,199-215`). A five-hour expiry is a local assumption, not the CDN's stated lifetime.
- Search relevance is weak: free text appends `lyrics`; Spotify enrichment selects `items[1]` by default and then performs substring matching (`Classes/Processors/SongProcessor.py:83-103`).
- `URLHandler.strip` claims to accept `youtu.be` and `music.youtube.com` but always reconstructs a `youtube.com/watch?v=` URL from the entire unmatched string (`Classes/Processors/URLHandler.py:66-72,91-94`); short-form URLs are therefore suspect.

## Security and operational findings

| Severity | Finding | Evidence and impact |
|---|---|---|
| High | **Unauthenticated, unmetered work amplification** | All API routes are open GETs (`_server.py:101-135`) and the service binds publicly (`Classes/Processors/WSGIElements.py:19-24`). Each cache miss can start effectively infinite yt-dlp retries, a Spotify call, database writes, and a full upstream audio download. There is no per-client quota, global concurrency cap, or backpressure. |
| High | **Memory and bandwidth exhaustion** | Every cached song starts an upstream GET and appends all 1 KiB chunks to `data_queue` without a byte cap or queue eviction (`Classes/Processors/SongData.py:70-83,86-117`). Cached objects may live about four hours (`Classes/Processors/SongProcessor.py:144-153`). `/api/audio` can be called repeatedly while the same full body remains resident. |
| High | **Server-side request/amplification surface** | User input reaches yt-dlp (`Classes/Processors/SongProcessor.py:66-90,174-196`), while database-controlled `AUDIO_URL` values are fetched by the server (`Classes/Processors/SongData.py:70-75`). There is no egress allowlist, redirect validation, timeout, response-size cap, content-type check, or private-address denial. Compromise or poisoned cache data can turn the host into a network relay. |
| High | **Stored/reflected XSS in the bundled web UI** | Extractor metadata is inserted into ordinary Jinja templates without autoescaping (`_server.py:59-62`; `Static/HTML/Prepared.html:2-11`). `Template(string).render()` also interprets user-supplied Jinja syntax before lookup (`_server.py:108-109`). A crafted title or thumbnail URL can become markup/script in the service's origin. |
| Medium | **Availability failures are hidden or unbounded** | yt-dlp catches every exception and returns `None` implicitly after all instances fail (`Classes/Processors/YTDLP.py:42-46`); the audio request then dereferences `None` (`_server.py:133-135`). Database initialization and fetch waiting use one-second polling loops (`Classes/Processors/DBHolder.py:42-58`; `Classes/Processors/SongProcessor.py:207-212`). There is no end-to-end resolver deadline or bounded client wait; the audio download also has no HTTP timeout. |
| Medium | **Weak proxy/request handling and observability** | `_server.py:152-169` mutates `request.path` and conditionally trusts forwarded values. `WSGIElements.py:37-50,99-113` suppresses broad exceptions and disables normal request/error logging. This impedes abuse detection and incident reconstruction. |
| Medium | **Cookie credential risk** | A Netscape cookie jar is loaded into both yt-dlp instances (`Classes/Processors/YTDLP.py:33`). Although `.gitignore:165-168` ignores `/Hidden/`, the tracked `Hidden/YT-COOKIES:1-3` proves the ignore rule does not protect already tracked credential files. The audited file contains headers only, but operators can expose account sessions if they populate it. |
| Medium | **Public service has no data-use boundary** | Search strings are sent to YouTube and Spotify, while IP/user-agent/device/browser metadata is retained in encrypted visitor cookies (`Hidden/dynamicWebsite.py:123-205,231-254`). There is no privacy policy, retention schedule, or operator identity in the tracked tree. Clostel users would disclose their searches to this service. |

The service also has correctness defects that make it unsuitable as infrastructure: a missing Spotify API can raise `StopIteration` during enrichment, thumbnail selection uses the first rather than best thumbnail (`Classes/Processors/SongProcessor.py:74,92-103`), and database writes have no visible uniqueness constraints or migrations.

## Licensing and rights concerns

1. **No software license.** The audited Git tree contains no `LICENSE`, `COPYING`, or equivalent. The README's “open-source” and “free to use” wording (`README.md:54-59`) does not grant copyright permission. Clostel must not vendor, copy, modify, or ship this code unless the owner supplies an explicit license or written permission. This conclusion is independent of music rights.
2. **No media-rights provenance.** Neither the database schema nor API response records a content license, rights holder, territory, expiry basis, attribution requirement, or takedown contact (`Classes/Holders/DBTables.py:1-27`; `Classes/Processors/SongData.py:34-49`). A Spotify match or YouTube video ID is not a music license.
3. **YouTube extraction is incompatible with a normal Clostel playback flow absent approval.** The service loads account cookies and asks yt-dlp for a direct audio URL (`Classes/Processors/YTDLP.py:13-33`). [YouTube's Terms of Service](https://www.youtube.com/t/terms) limit viewing/listening to personal, non-commercial use and prohibit reproduction, download, distribution, automated access, circumvention, and streaming music from the service except as expressly authorized or with prior written permission. [YouTube API Developer Policies](https://developers.google.com/youtube/terms/developer-policies) separately prohibit undocumented APIs, scraping, downloading/importing/caching/storing audiovisual content without prior written approval, and offline playback. `AUDIO_URL` and `/api/audio` are therefore not safe Clostel defaults.
4. **Spotify use is not a general metadata license for this design.** The implementation uses Spotify only to discover an ID and then resolves YouTube audio (`Classes/Processors/SongProcessor.py:76-103`). [Spotify Developer Policy](https://developer.spotify.com/policy) requires attribution/backlinks, prohibits standalone metadata/cover products, prohibits products integrated with another service's streams/content, and prohibits mixing Spotify content with other audio. [Spotify Developer Terms](https://developer.spotify.com/terms) prohibit stream ripping, transfer to another service except limited user-data cases, and indefinite storage. An approved Spotify metadata-only design would still need separate review; the present design does not meet that boundary.
5. **Artwork, lyrics, metadata, and audio require separate treatment.** The service returns YouTube thumbnails and a lyrics string but supplies no license or attribution (`Classes/Processors/SongData.py:34-49`; `Static/HTML/Prepared.html:3,7-11`). A track-level rights check cannot automatically clear these fields.
6. **Clostel's existing yt-dlp path does not make this safer.** Clostel already resolves yt-dlp audio locally (`Clostel/lib/core/services/yt_dlp_audio_resolver.dart:17-76`). Adding BhariyaMusic would add another unauthenticated hop, proxy, and server-side extractor without adding rights evidence or a stable schema.

## Secrets, cookies, database, and filesystem requirements

These are requirements of the external service; **Clostel must require none of them**.

- **Runtime secret module:** `Hidden.Secrets.ServerSecrets.fernetKey`, `CoreValues.appName/webRoute/webPort`, and `DBSecrets.DBHosts/DBUser/DBPassword/DBName` are imported by `_server.py:13-14,93-98` and exemplified in `Hidden/Secrets.sample.py:1-15`. `folderLocation` and `RequiredFiles` are additionally required but omitted from the sample.
- **Spotify credentials:** The `spotify_apis` table stores `client_id`, `secret`, and `owner` (`Classes/Holders/DBTables.py:22-27`). `SpotifyAPICollection` reads client IDs/secrets from MySQL and asks Spotipy to cache auth material under `Temp/Auto/<client_id>` (`Classes/Processors/SpotifyAPI.py:21-27`; `Classes/Holders/FileInvolved.py:8-9`). These are server secrets/tokens, not Flutter configuration.
- **YouTube cookies:** `Hidden/YT-COOKIES` is a Netscape cookie jar loaded into yt-dlp (`Classes/Holders/FileInvolved.py:31-32`; `Classes/Processors/YTDLP.py:33`). It may contain session/account credentials and must be supplied only through a protected server secret store, never a Clostel bundle or repository.
- **MySQL:** Pooled connections use the configured host list, user, password, and database (`Classes/Processors/DBHolder.py:22-39`). The code expects `songs`, `aliases`, and `spotify_apis` tables matching `Classes/Holders/DBTables.py`; no schema migration is provided. Stored data includes query aliases, YouTube/Spotify identifiers, metadata, artwork URLs, and expiring audio CDN URLs.
- **Filesystem:** Runtime paths derive from `folderLocation` and expect `Static`, `Hidden`, `Temp/Auto`, and several static subfolders (`Classes/Holders/FileInvolved.py:1-17`). Spotipy token caches, HTML files, cookies, and temporary/runtime data require separate permissions and retention rules.

For any independently operated instance, secrets should come from a secret manager; database credentials should be least-privilege and encrypted in transit; cookies should be purpose-limited and revocable; logs should exclude query/cookie/token data; and the database/filesystem should not be reachable from Clostel clients.

## Safe optional integration boundary for Clostel

### Allowed boundary: opt-in metadata experiment only

Implement, if separately approved, a disabled-by-default Clostel data-layer adapter conforming to `Clostel/lib/core/services/music_catalog.dart:3-6`. It may call only HTTPS `/api/prepare/{query}` and `/api/fetch/{id}` against one operator-approved origin. It must:

- be explicitly enabled by the user/operator and excluded from the default `MusicCatalogChain`; return no featured content;
- map stable identity as `bhariyamusic:<validated ID>`, retain only validated title/duration and an explicitly approved source landing URL, and use non-fabricated values such as `Unknown` for missing artist/album/genre;
- set `source: 'bhariyamusic'`, leave `streamUrl`, `filePath`, and `assetPath` null, register no `TrackFileResolver`, and set `playbackKind: PlaybackKind.unknown` so `JustAudioPlaybackService` rejects playback (`Clostel/lib/core/services/playback_service.dart:50-71`);
- discard `AUDIO_URL`, lyrics, artwork, and Spotify fields by default unless the operator and applicable provider terms explicitly approve each field; never call `/api/audio`;
- require an exact `https` origin allowlist, no URL userinfo, revalidate every redirect, cap query length, use short connect/read timeouts and a small response-byte limit, reject non-JSON/unexpected content types, and never place cookies or bearer credentials in a Flutter binary;
- validate the 30-character ID, finite non-negative duration, bounded strings, and URL scheme/host before domain mapping; treat every response as untrusted, as required by Clostel's architecture rules;
- apply low per-instance concurrency, timeout/circuit-breaker behavior, no persistent Clostel cache by default, and provider-specific attribution/source labeling. The existing chain already isolates provider failures (`Clostel/lib/core/data/music_catalog_chain.dart:28-44`), but this adapter should still be opt-in rather than a silent fallback;
- disclose that search text and network metadata reach a third-party operator, and use fixture-based contract/unit tests rather than tests against the public DDNS endpoint.

### Gates before even that experiment

Obtain: (1) explicit permission to use the API and a stable contact/SLA; (2) a privacy/retention statement; (3) confirmed provider terms for any displayed metadata; (4) origin-level authentication or a private gateway, because the current API has none; and (5) a Clostel fixture covering success, nulls, 404-as-200-error, timeout, malformed JSON, oversized response, and invalid redirects.

### Prohibited boundary

Do not use this service for playback, download/offline storage, cross-provider queue mixing, credential/cookie handling, user-account YouTube access, default/fallback catalog traffic, or redistribution. A future playback integration would require a separate architecture and legal review, a documented license for every audio work, provider approval where required, and an official playback path; it must not be enabled by merely setting `streamUrl` to `AUDIO_URL` or `/api/audio/{id}`.

## Final recommendation

Keep BhariyaMusic **outside Clostel's default build and production source chain**. At most, preserve its HTTP shape as a fixture for a disabled metadata-only experiment. The current service should not receive Clostel users, cookies, secrets, or playback traffic.

# Keyless and public music APIs for Clostel

**Research date:** 2026-09-25  
**Scope:** Publicly reachable music/catalog APIs that may be usable without an API key, plus the requested commercial catalogs. This is a technical and licensing-risk assessment, not legal advice. “Safe to integrate” means that the documented API can be used without scraping or bypassing authentication; it does **not** mean that every result is safe for Clostel’s commercial use.

## Executive summary

| Provider | Keyless? | Search/catalog | Playback | Production safety for Clostel |
|---|---:|---|---|---|
| **ccMixter** | Yes, for the public read-only Query API | Music search by text, tags, user, license, and playlists | Full MP3/FLAC and other files are exposed; no preview-only rule is documented | **Conditional.** Strong keyless full-track candidate, but the API is beta, has no published SLA/rate limit, and requires per-track license handling. |
| **Internet Archive** | Yes, for public search and metadata reads | Very large, heterogeneous item catalog; search is not music-specific | Full item files when present; rights and restrictions vary per item | **Conditional.** Good read-only archival fallback, not a dependable normalized music catalog. |
| **Openverse** | Yes, anonymously with low limits | Broad audio search across third-party sources | Mixed: some results are full files, some are previews; provider-specific behavior remains | **Conditional for discovery/metadata; not a blanket playback source.** Verify every result’s license, host terms, and whether the URL is a full file. |
| **Wikimedia Commons** | Yes, for public reads | MediaWiki search and file metadata; includes music, field recordings, and sound effects | Full audio files when public and available | **Conditional and supplementary.** Rights are generally free-license oriented, but this is not a music catalog and file-level checks remain necessary. |
| **Deezer** | Public search does not show a key requirement, but a developer login is required to accept terms | Albums, artists, playlists, radio, search, and tracks | Treat the general API as **30-second extracts only**; do not expose full-track URLs | **No for production.** Deezer’s terms are non-commercial/private-use and prohibit offline storage, DRM bypass, and unauthorized full-track use. |
| **Jamendo** | No: every call needs `client_id` | Structured music discovery: tracks, albums, artists, tags, charts, playlists, autocomplete, similar tracks, and radios | Full-track stream URLs; download is separately controlled by `audiodownload_allowed` | **Conditional, potentially the best production catalog after commercial licensing.** Not keyless. |
| **Audius** | No under the current official SDK/API-plan documentation | Track, user, playlist, trending, recommendation, and search APIs | Full-track streaming is supported where API access is permitted | **Conditional.** Requires an API key, current license/OML review, and per-track settings checks. |

## Important interpretation of “keyless”

- **No key, but registration still required:** Deezer’s public API documentation does not require a key, but its developer site says a login is needed to accept the API terms. This is not a good fit for a “zero-credential” production integration.
- **No key for reads, credentials for writes:** Internet Archive, ccMixter, Openverse, and Wikimedia Commons expose useful public read APIs. Their terms and etiquette still apply, and they do not grant unrestricted rights to all content.
- **Aggregator does not mean uniform rights or uniform files:** Openverse exposes a `url` for each result, but the URL may point to a full file, a preview, or a source-specific representation. Clostel should model this uncertainty instead of treating every result as a playable full track.

## Provider findings

### 1. ccMixter — strongest keyless full-track candidate

**Official documentation**

- [Query API 2.0 (beta)](https://ccmixter.org/query-api)
- [ccMixter terms of use](https://ccmixter.org/terms)
- [Official API discussion: read-only API](https://ccmixter.org/thread/3254)
- [Public music search UI](https://dig.ccmixter.org/)

**Authentication**

The documented remote Query API is invoked by URL at `https://ccmixter.org/api/query` and the API discussion identifies it as read-only. The documentation shows no API key, OAuth flow, or registration requirement for public search. Clostel should still accept the site terms and avoid write endpoints; ccMixter’s API is not a user-upload or library API.

**Search and catalog**

The Query API supports URL parameters for free-text `search`, `tags`, `user`, `playlist`, `remixes`, `lic` (license filters), sorting, and pagination with `limit` and `offset`. It can return JSON, XML, CSV, RSS/Atom, M3U, and HTML. The API’s `files` data includes file names, formats, durations, sizes, and download URLs. The live JSON response includes full MP3 and FLAC URLs for an upload; this is not merely a 30-second preview endpoint.

**Playback: full track**

There is no documented preview-only restriction in the Query API. Results can include complete MP3/FLAC files, and the documentation includes stream-link templates. A Clostel adapter should select a playable public file, check its MIME type and duration, and avoid assuming that every upload has the same format or that every stem is a complete mix.

**Licensing and attribution**

The terms say that different Creative Commons licenses may apply to different tracks. Each track must be used according to its own license. The terms require attribution in the manner required by the author/licensor, require the license terms to be made clear when reusing a work, prohibit removal or alteration of copyright/trademark/name notices, and prohibit using a track to advertise or promote unrelated work. The site does not grant a blanket commercial license: NC, ND, and SA terms still apply where selected. Clostel must retain the track page, creator, license URL/version, and any additional terms with the playback record.

**Rate limits and production caveats**

No numeric rate limit or SLA is published. The API is explicitly labeled beta; the site terms prohibit overburdening, damaging, or impairing the service, and permit suspension or modification. The API is read-only and old enough that a provider outage or template error can affect an integration. The current public site also does not promise a stable versioned JSON contract.

**Safe to integrate?**

**Conditionally yes, for a read-only prototype or supplemental catalog.** It is the best keyless option examined for full-track playback, but Clostel should not make it the only production source until the API contract, licensing workflow, and availability have been validated with a small, low-volume integration. Do not scrape the HTML site, bypass limits, or infer a commercial right from the word “free.”

---

### 2. Internet Archive — keyless archival catalog, not a music service

**Official documentation**

- [Internet Archive Developer Portal](https://archive.org/developers/)
- [Advanced Search](https://archive.org/advancedsearch.php)
- [Tools and APIs](https://archive.org/developers/index-apis.html)
- [Item Metadata API](https://archive.org/developers/metadata.html)
- [Metadata Read](https://archive.org/developers/md-read.html)
- [Internet Archive metadata schema](https://archive.org/developers/metadata-schema/index.html)
- [Bots and automated access](https://archive.org/developers/bots.html)

**Authentication**

The public Advanced Search endpoint and Metadata Read endpoint are usable without credentials. Metadata writes require S3 credentials or Internet Archive cookies. Clostel only needs the public read path for search, metadata, and public files.

**Search and catalog**

`advancedsearch.php` supports Solr-style queries, field selection, rows/page, and JSON/XML output. A query such as `mediatype:audio` returns a very large result set, and Clostel can add `title`, `creator`, `subject`, `collection`, and other indexed metadata fields. The response is item-oriented rather than track-oriented. The Metadata API returns item metadata plus a `files` list with names, formats, sizes, checksums, and server information. A music adapter therefore needs its own normalization and relevance logic.

**Playback: generally full files**

Public items can contain original and derived audio files such as MP3, FLAC, WAV, or OGG. The metadata response supplies the item’s file list and downloadable server locations; Clostel can construct the normal Archive.org download URL or use the returned server information. There is no general 30-second preview contract. However, “audio” includes much more than music: spoken-word, field recordings, radio, podcasts, sound effects, and inaccessible or restricted items can appear. A file can also be removed, geo-restricted, or unavailable even when its metadata remains.

**Licensing and attribution**

The Developer Portal says Internet Archive does not assert new copyright or other proprietary rights over material in its database. The metadata schema provides `licenseurl` and `rights` as item/file-level fields. This is not a blanket public-domain or Creative Commons warranty. Clostel must read the item’s rights fields, inspect the item description, preserve the source link, and exclude items with unclear, restricted, or incompatible rights. Do not infer a license from the fact that an item is downloadable.

**Rate limits and production caveats**

No fixed public read limit is published in the portal. The REST documentation defines `429 Too Many Requests` and `Retry-After` behavior, and the current automated-access guide requires a descriptive `User-Agent`, delays for bulk work, honoring `429`, caching, low concurrency, and exponential backoff. Advanced Search is a broad catalog query surface and should not be used for unbounded result crawling. The catalog is heterogeneous, metadata quality varies, and file rights can differ within one item.

**Safe to integrate?**

**Conditionally yes for a read-only archival or field-recording catalog.** Use the official APIs, a descriptive User-Agent, conservative concurrency, caching, and per-item rights checks. It is not a safe default source for a polished commercial music player without a curation and rights-review layer.

---

### 3. Openverse — useful keyless discovery and attribution layer

**Official documentation**

- [Openverse API](https://api.openverse.org/)
- [Openverse API documentation](https://docs.openverse.org/api/)
- [Audio list endpoint](https://api.openverse.org/v1/audio/)
- [Authentication and throttling](https://docs.openverse.org/api/reference/authentication_and_throttling.html)
- [Openverse API Terms of Service](https://wordpress.github.io/openverse-api/terms_of_service.html)
- [Openverse “Made with Openverse” guidance](https://docs.openverse.org/api/reference/made_with_ov.html)

**Authentication**

The API supports anonymous requests. A live anonymous response to `GET /v1/audio/?page_size=1&q=music` includes the rate-limit headers described below. Registration can be used to obtain higher limits, but Clostel must not assume anonymous access is appropriate for production-scale traffic.

**Search and catalog**

`GET /v1/audio/` supports audio search and pagination. Results include title, creator, foreign landing page, source/provider, license and license URL, attribution string, duration, media type, direct `url`, and optional `alt_files`. The catalog aggregates metadata from third-party providers rather than operating one uniform music store. This makes Openverse useful for discovery, license-filtered search, and attribution, but not ideal as a single canonical track database.

**Playback: mixed full files and previews**

The response’s `url` is an audio URL, but its semantics are provider-specific. The official examples show a Jamendo storage URL for a music track and a Freesound `hq.mp3` preview for a sound. Some results have no alternate files. Clostel must treat playback capability as `full`, `preview`, or `unknown` based on provider, file type, duration, and a permitted probe; it must not label every Openverse result as a full track.

**Licensing and attribution**

Openverse’s terms say the API aggregates metadata about openly licensed content hosted by third parties; Openverse does not own or control the content, does not verify licensing status, and makes no warranty about the metadata. Clostel is responsible for independently checking the rights and host terms. The API terms require proper attribution to CC-licensed works, compliance with the hosting platform’s terms, and prominent indication that an app uses the Openverse API without implying endorsement. The terms prohibit scraping the catalog, using multiple machines to evade limits, or harming the service. They also reserve the right to charge fees for commercial or heavy use.

**Rate limits and production caveats**

The official anonymous response headers state `20/min` burst and `200/day` sustained limits. The authentication/throttling documentation is the canonical source for changing tiers; clients should read response headers and back off rather than hard-code an assumption that the current anonymous numbers are permanent. The terms permit suspension or termination and limit scraping and circumvention. Commercial or heavy use may require a fee.

**Safe to integrate?**

**Conditionally yes for metadata, discovery, and links; not as a blanket commercial playback source.** Clostel can use Openverse as a search and attribution adapter if it preserves the returned attribution, follows the direct source policy, verifies each provider’s terms, and checks whether the audio is a full file. It should not mirror the Openverse catalog, proxy or rehost audio by default, or infer commercial permission from a license string alone.

---

### 4. Wikimedia Commons — keyless free-media fallback, not a music API

**Official documentation**

- [Wikimedia Commons API](https://commons.wikimedia.org/wiki/Commons:API)
- [MediaWiki Action API](https://www.mediawiki.org/wiki/API:Action_API)
- [MediaWiki API etiquette](https://www.mediawiki.org/wiki/API:Etiquette)
- [Wikimedia Commons licensing policy](https://commons.wikimedia.org/wiki/Commons:Licensing)
- [Wikimedia Foundation Terms of Use](https://foundation.wikimedia.org/wiki/Policy:Terms_of_Use)
- [Example Commons audio search](https://commons.wikimedia.org/w/api.php?action=query&generator=search&gsrsearch=filetype%3Aaudio%20music&gsrnamespace=6&gsrlimit=1&prop=imageinfo&iiprop=url%7Cextmetadata&format=json)

**Authentication**

The MediaWiki Action API supports anonymous read requests. Authentication is needed for edits and other state-changing operations, which Clostel does not need for a read-only catalog.

**Search and catalog**

The Commons API exposes MediaWiki search, file pages, image information, URLs, and extended metadata. Clostel can search the file namespace for audio, then request `imageinfo` and `extmetadata`. The example response demonstrates a public audio file with a direct URL, creator, description page, license name, usage terms, attribution requirement, and license URL. It is a general media repository, so search results include sound effects, spoken word, historical recordings, and non-music audio.

**Playback: full files when the file is public**

The `imageinfo` response provides the public original file URL. There is no music-preview restriction in the API; playback is of the public file or an available transcoded representation. Clostel must still check whether the file is public, whether the file is a complete work, and whether the description page contains additional restrictions.

**Licensing and attribution**

Commons’ licensing policy says the repository accepts free content and public-domain material rather than fair-use files or NC-only licenses. Reusers must comply with the license on each file’s description page, preserve required attribution, and check non-copyright restrictions. The Foundation terms make the reuser responsible for the license and prohibit abusive automated use. The `Commons:API` page also warns about “do not use or index” tags; Clostel must honor those tags and should not index a file merely because the API returned it.

**Rate limits and production caveats**

The MediaWiki etiquette page says there is no hard speed limit on reads, but requests should be considerate, serial where practical, grouped, compressed, cached, and supplied with a descriptive `User-Agent`/`Api-User-Agent`. Wikimedia API requests are also subject to rate limits, and writes have separate limits. Bulk consumers should use Wikimedia’s recommended bulk/data services where available rather than hammering the Action API.

**Safe to integrate?**

**Conditionally yes as a supplemental, read-only source for freely licensed audio.** It is a good fit for public-domain, historical, or field-recording material after file-level license and restriction checks. It is not a replacement for a music-specific provider.

---

### 5. Deezer — public metadata/search, but not a production Clostel provider

**Official documentation**

- [Deezer for developers](https://developers.deezer.com/api)
- [Deezer integration guidelines](https://developers.deezer.com/guidelines)
- [Deezer API terms of use](https://developers.deezer.com/termsofuse)
- [Deezer search API](https://api.deezer.com/search?q=music)

**Authentication**

The public API does not document a key parameter for ordinary search and track metadata. However, Deezer’s developer site says a developer must log in to accept the terms and conditions of the simple API. User-library features require user authentication and permissions. Clostel should therefore classify Deezer as “no API key,” not “no registration or no contract.”

**Search and catalog**

Deezer exposes search plus album, artist, playlist, radio, editorial, user, and track entities. It is a mainstream commercial music catalog with strong metadata, but that same catalog is not a reusable open-license catalog.

**Playback: 30-second extracts for the general API**

Deezer’s guidelines describe 30-second listening restrictions for unlogged and freemium users and state that the API’s available tools are limited to 30-second extracts. The guidelines also contain separate full-track rules for approved plugins/SDKs; those are not permission to expose full URLs from Clostel’s own native API. Clostel should model Deezer as preview-only and must not attempt to obtain, proxy, or expose a full-track URL.

**Licensing and attribution**

The terms grant no rights in Deezer content. They limit use to non-commercial purposes and a non-commercial environment, restrict content to private family use, prohibit unauthorized streaming/download/sharing, prohibit DRM bypass, prohibit offline/local audio storage, and impose branding and user-notice requirements. Deezer can monitor use and restrict or remove API access at any time.

**Rate limits and production caveats**

No numeric rate limit is published. The terms reserve the right to monitor technical use, modify or remove functionality, and restrict or remove access. Geographic rights and user state also affect what is playable. A production Clostel release would be outside the stated non-commercial scope.

**Safe to integrate?**

**No for a production Clostel music app.** A local development-only metadata adapter or a clearly marked preview experience may be useful after accepting the terms, but even preview playback needs the Deezer-approved integration path. Do not scrape Deezer, bypass authentication, bypass DRM, cache audio, or expose full-track URLs.

---

### 6. Jamendo — strongest structured full-track option, but not keyless

**Official documentation**

- [Jamendo API introduction](https://developer.jamendo.com/v3.0/docs)
- [Authentication](https://developer.jamendo.com/v3.0/authentication)
- [Tracks API](https://developer.jamendo.com/v3.0/tracks)
- [Track file/stream endpoint](https://developer.jamendo.com/v3.0/tracks/file)
- [Autocomplete](https://developer.jamendo.com/v3.0/autocomplete)
- [Similar tracks](https://developer.jamendo.com/v3.0/tracks/similar)
- [Jamendo API terms](https://devportal.jamendo.com/api_terms_of_use)

**Authentication**

Every API call requires a `client_id`. A developer must create an account and application; the test client ID shown in the documentation is explicitly for testing only. Private user data and write methods require OAuth2. Clostel must keep the production client ID in configuration rather than hard-coding it, although the API’s simple client-ID scheme is not equivalent to a secretless public endpoint.

**Search and catalog**

Jamendo provides more than 20 read methods over a catalog of roughly half a million tracks. The documented surface includes tracks, albums, artists, tags, autocomplete, charts, feeds, playlists, reviews, similar tracks, and radios. Search supports free text, names, tags, genres, instruments, mood, language, duration, release date, license filters, ordering, boosting, and grouping.

**Playback: full-track stream; download is separately controlled**

The Tracks API returns `audio` as the stream URL and `audiodownload` as a separate download URL. It supports `mp31`, `mp32`, `ogg`, and `flac` for the returned audio field. The `/tracks/file` endpoint redirects to a requested file and supports `action=stream`; it is not a preview-only API. The artist can set `audiodownload_allowed`, and the file endpoint returns an error when downloading is not allowed. Clostel should use the stream field for playback and treat the download field as a separate permission, not as a reason to add offline storage.

The radio stream method is currently documented with a warning that its stream link is not working and may never be fixed. It should not be part of the initial production design.

**Licensing and attribution**

Jamendo content is published under a Creative Commons license selected for each item. Clostel must use each track under its actual license. The API terms require crediting the Jamendo member as creator, crediting Jamendo as provider, and providing a direct backlink from each content item to its Jamendo page. The API terms limit non-commercial use and say commercial use, including advertising or revenue, requires contacting Jamendo licensing. They also prohibit designing an app that replicates Jamendo, require reasonable privacy controls, and prohibit offline access except for limited caching necessary to operate the app. The radio documentation separately states that direct or indirect commercial radio use requires a commercial license.

**Rate limits and production caveats**

No fixed general rate limit is published. Applications at or above 500,000 hits, or likely to exceed that level, must contact Jamendo. High-consumption applications go through review; Jamendo may issue warnings, impose temporary call limits, restrict access, or ban an application that does not respond or does not provide required information. The API is a commercial service with terms that can change.

**Safe to integrate?**

**Conditionally yes, and probably the best first production target for a structured full-track catalog after commercial licensing.** It is not a keyless option. Clostel should obtain the appropriate Jamendo commercial/API agreement, implement the required attribution/backlink flow, obey no-offline rules, and have a fallback when a track disallows download or when a radio endpoint is unavailable.

---

### 7. Audius — open catalog with full streaming, but current API-key requirement

**Official documentation**

- [Audius developer documentation](https://docs.audius.org/)
- [Audius REST API reference](https://docs.audius.org/api/)
- [Official SDK README and API plans](https://github.com/AudiusProject/apps/blob/main/packages/sdk/README.md)
- [Audius terms update and Open Music License summary](https://blog.audius.co/posts/audius-terms-of-service-update)
- [Official API backend](https://github.com/AudiusProject/api)

**Authentication**

The current official SDK documentation says to create an API key in the Audius API Plans page. The API key is safe to include in frontend/mobile code; a backend bearer token is for acting on behalf of users and must never be embedded in a mobile app. User login uses OAuth 2.0 Authorization Code with PKCE. Older public endpoints may be visible without credentials, but Clostel should not design around undocumented legacy behavior; the documented current integration is not keyless.

**Search and catalog**

The REST API supports querying and streaming tracks, users, and playlists. The SDK exposes search and discovery for users, tracks, and playlists, plus trending/recommendation and user-curation operations. This is a music-specific catalog rather than an archival metadata dump.

**Playback: full-track stream where permitted**

Audius documents streaming as a first-class API operation, and its open-source content-node documentation describes a streamable MP3 endpoint with range-request support. This is a full-track stream model, not a 30-second preview model. Availability is nevertheless controlled by the track’s current API-access and visibility settings.

**Licensing and attribution**

Audius’ July 2025 terms update says uploaded tracks can default to All Rights Reserved, artists can choose Creative Commons options, and a custom Open Music License governs use of tracks through third-party API applications. API access is on by default unless an artist opts out, and the artist’s visibility and pricing/access settings carry over to the API. Clostel must therefore inspect the current track license/API-access state and the current API Terms/OML; it must not assume that “open network” means unrestricted commercial reuse. Attribution and any OML-specific notice must be preserved per track.

**Rate limits and production caveats**

The official SDK README lists a free plan at 10 requests/second and 500,000 requests/month, with an unlimited plan available by contacting Audius. The API key, plan usage, and OAuth implementation must be designed for mobile. Audius can change terms and access settings, and the catalog is decentralized/open, so content quality and rights metadata need validation just like any other provider.

**Safe to integrate?**

**Conditionally yes, but not as a keyless provider.** It is a good candidate for an open full-track catalog after Clostel has an API key, a current legal review of the API Terms and OML, and a per-track policy that excludes opt-out or incompatible content.

## Recommendation for Clostel’s provider order

### Immediate keyless prototype order

1. **ccMixter** — first choice for keyless full-track experimentation. Use the public read-only Query API, normalize the JSON file list, require an explicit license record, expose no download/offline action, and keep traffic low. Treat the beta API as experimental.
2. **Internet Archive** — second choice for archival, public-domain, historical, and field-recording material. Use Advanced Search plus Metadata Read, require per-item rights validation, and send a descriptive User-Agent.
3. **Openverse** — third choice for broad discovery, search suggestions, and attribution. Use it to find candidate works, then follow the foreign landing page/provider and verify the actual file; do not assume every `url` is a full track.
4. **Wikimedia Commons** — fourth choice for supplementary freely licensed audio and public-domain material. It is not music-specific, so keep it separate from the main catalog ranking.

### Commercial production order

1. **Jamendo, after a commercial/API agreement** — best documented structured music catalog with full-track streaming, search/discovery, and explicit download controls. It is not keyless.
2. **Audius, after an API key and OML/API-terms review** — strong open full-track streaming candidate, subject to artist settings and per-track licensing.
3. **ccMixter and Internet Archive as supplemental providers** — use only with strict per-item/per-track rights checks, conservative request rates, and a fallback when a file is removed or unavailable.
4. **Openverse as an attribution/discovery layer** — do not make it the canonical playback provider unless each result is promoted through its underlying source and the source’s terms are accepted.
5. **Wikimedia Commons as a supplemental source**, not the default music catalog.
6. **Deezer excluded from production** — its public API is preview-oriented and its current developer terms are non-commercial/private-use and prohibit offline storage. Do not use scraping, full-track URL extraction, DRM bypass, or auth bypass.

## Implementation guardrails for Clostel

- Keep provider adapters behind the project’s provider-neutral catalog/playback interfaces; do not leak provider URLs or response shapes into the domain.
- Normalize a `playbackKind` value such as `full`, `preview`, or `unknown`; never infer “full” solely from the existence of a URL.
- Preserve `provider`, `providerTrackId`, source/landing URL, creator, license name/version/URL, attribution text, and the timestamp when rights were checked.
- Apply a rights policy before returning a result to a user. For CC catalogs, exclude NC/ND licenses when the product use requires commercial or remix rights; do not treat “Creative Commons” as one blanket permission.
- Never implement offline downloads for Deezer or Jamendo without explicit written permission. Openverse, ccMixter, IA, Commons, and Audius also need their own terms/track-level checks.
- Use descriptive User-Agent headers, bounded concurrency, caching, backoff, and `429`/`Retry-After` handling for public/community services.
- Treat all API responses as untrusted input, as required by the repository rules. Do not follow arbitrary URLs from metadata without validating scheme, host, content type, and licensing context.
- Do not scrape provider websites, reverse-engineer protected endpoints, reuse test credentials, or bypass authentication/rate limits.

## Source index

- [Deezer API](https://developers.deezer.com/api), [guidelines](https://developers.deezer.com/guidelines), [terms](https://developers.deezer.com/termsofuse)
- [Jamendo API docs](https://developer.jamendo.com/v3.0/docs), [authentication](https://developer.jamendo.com/v3.0/authentication), [tracks](https://developer.jamendo.com/v3.0/tracks), [file/stream](https://developer.jamendo.com/v3.0/tracks/file), [terms](https://devportal.jamendo.com/api_terms_of_use)
- [Audius docs](https://docs.audius.org/), [API reference](https://docs.audius.org/api/), [SDK/API plans](https://github.com/AudiusProject/apps/blob/main/packages/sdk/README.md), [terms update](https://blog.audius.co/posts/audius-terms-of-service-update)
- [Internet Archive Developer Portal](https://archive.org/developers/), [Advanced Search](https://archive.org/advancedsearch.php), [Metadata Read](https://archive.org/developers/md-read.html), [metadata schema](https://archive.org/developers/metadata-schema/index.html), [automated access](https://archive.org/developers/bots.html)
- [ccMixter Query API](https://ccmixter.org/query-api), [terms](https://ccmixter.org/terms), [read-only API discussion](https://ccmixter.org/thread/3254)
- [Openverse API](https://api.openverse.org/), [audio endpoint](https://api.openverse.org/v1/audio/), [throttling](https://docs.openverse.org/api/reference/authentication_and_throttling.html), [terms](https://wordpress.github.io/openverse-api/terms_of_service.html)
- [Wikimedia Commons API](https://commons.wikimedia.org/wiki/Commons:API), [MediaWiki API etiquette](https://www.mediawiki.org/wiki/API:Etiquette), [Commons licensing](https://commons.wikimedia.org/wiki/Commons:Licensing), [Foundation terms](https://foundation.wikimedia.org/wiki/Policy:Terms_of_Use)

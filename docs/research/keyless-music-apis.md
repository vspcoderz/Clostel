# Public music metadata/catalog APIs and yt-dlp for Clostel

**Research date:** 2026-09-25  
**Scope:** Official public and developer music metadata/catalog APIs that may be usable without a key or with optional authentication, plus a separate assessment of yt-dlp as a non-API bridge for sites where the app has explicit permission. This is a technical and licensing-risk assessment, not legal advice. “Safe to integrate” means that the documented API can be used without scraping or bypassing authentication; it does **not** mean that every result is safe for Clostel’s commercial use.

## Executive summary

| Provider | Keyless? | Search/catalog | Playback | Production safety for Clostel |
|---|---:|---|---|---|
| **ccMixter** | Yes, for the public read-only Query API | Music search by text, tags, user, license, and playlists | Full MP3/FLAC and other files are exposed; no preview-only rule is documented | **Conditional.** Strong keyless full-track candidate, but the API is beta, has no published SLA/rate limit, and requires per-track license handling. |
| **Internet Archive** | Yes, for public search and metadata reads | Very large, heterogeneous item catalog; search is not music-specific | Full item files when present; rights and restrictions vary per item | **Conditional.** Good read-only archival fallback, not a dependable normalized music catalog. |
| **Openverse** | Yes, anonymously; OAuth can unlock higher tiers | Broad audio search across third-party sources | Mixed: some results are full files, some are previews; provider-specific behavior remains | **Conditional for discovery/metadata; not a blanket playback source.** Verify every result’s license, host terms, and whether the URL is a full file. |
| **Wikimedia Commons** | Yes, for public reads | MediaWiki search and file metadata; includes music, field recordings, and sound effects | Full audio files when public and available | **Conditional and supplementary.** Rights are generally free-license oriented, but this is not a music catalog and file-level checks remain necessary. |
| **MusicBrainz** | Yes, no API key for public metadata; authentication for submissions and user-specific data | Structured artist, recording, release, release-group, work, label, and identifier metadata | **No audio files or streaming endpoint**; it is a metadata service | **Conditional metadata source.** Core data is CC0, but supplementary data is CC BY-NC-SA and the live web service is documented as free for non-commercial use. |
| **Apple iTunes Search API** | Yes, public search/lookup is documented without a key | Music, artist, album, song, and store metadata | `previewUrl` is a 30-second promotional preview; no full-track playback or download | **Conditional metadata/affiliate source.** Promo audio must promote the store item, be attributed, and must not be downloaded, saved, cached, or used as independent entertainment. |
| **Deezer** | Public search does not show a key requirement, but a developer login is required to accept terms | Albums, artists, playlists, radio, search, and tracks | Treat the general API as **30-second extracts only**; do not expose full-track URLs | **No for production.** Deezer’s terms are non-commercial/private-use and prohibit offline storage, DRM bypass, and unauthorized full-track use. |
| **Jamendo** | No: every call needs `client_id` | Structured music discovery: tracks, albums, artists, tags, charts, playlists, autocomplete, similar tracks, and radios | Full-track stream URLs; download is separately controlled by `audiodownload_allowed` | **Conditional, potentially the best production catalog after commercial licensing.** Not keyless. |
| **Spotify Web API** | No: developer registration, client credentials, and OAuth for user features | Rich commercial catalog metadata, search, playlists, and playback control | Official platform streaming is subject to Spotify’s rules; the 30-second `preview_url` is deprecated and cannot be standalone | **Not a download backend.** Current policy prohibits downloading/ripping, integrating content with another service’s streams, and several commercial uses. |
| **Audius** | Optional: most read-only endpoints work without credentials; a key raises limits and writes need keys | Track, user, playlist, trending, recommendation, and search APIs | Full-track streaming is supported where API access is permitted | **Conditional.** Review current API Terms/OML, preserve per-track settings, and do not assume API access means unrestricted reuse. |
| **YouTube Data API** | No: public reads still need an API key; OAuth is needed for user/private data and writes | Video, channel, playlist, search, and public metadata | Use the official player/embed path; the Data API is not a full-track audio/download API | **Conditional official integration only.** No extraction/download/offline path without YouTube’s prior written approval. |
| **yt-dlp (not an API)** | No API credential; target-site access, cookies, and terms still apply | Extractor-dependent metadata and format discovery for supported sites | Can download full media where the target site and rights permit | **Do not use as Clostel’s default catalog or downloader.** Legal, technical, packaging, and target-site terms make it a high-risk bridge. |

## Important interpretation of “keyless”

- **No key, but registration still required:** Deezer’s public API documentation does not require a key, but its developer site says a login is needed to accept the API terms. This is not a good fit for a “zero-credential” production integration.
- **No key for reads, credentials for higher limits or writes:** Internet Archive, ccMixter, Openverse, Wikimedia Commons, and MusicBrainz expose useful public read APIs. Audius’s current API reference says most read-only endpoints work without credentials, while keys provide higher limits and are required for writes. Their terms and etiquette still apply.
- **A key is still required even for public data in major catalogs:** Spotify and YouTube require app registration/credentials; YouTube’s Data API requires an API key for public reads and OAuth for user-specific or write operations. Jamendo requires `client_id` on every call.
- **Aggregator does not mean uniform rights or uniform files:** Openverse exposes a `url` for each result, but the URL may point to a full file, a preview, or a source-specific representation. Clostel should model this uncertainty instead of treating every result as a playable full track.
- **Software permission is not media permission:** yt-dlp’s own license covers the tool, not the music, audio, metadata, artwork, or rights in content extracted from a target site. The target site’s terms and the rights holder’s permissions still control.

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

The API supports anonymous requests. The current authentication/throttling documentation describes OAuth applications with `standard` and `enhanced` rate-limit tiers, but does not publish a stable numeric anonymous burst or daily allowance. Registration can be used to obtain a higher tier; Clostel should not assume anonymous access is appropriate for production-scale traffic and should read the response headers rather than hard-code a historical number.

**Search and catalog**

`GET /v1/audio/` supports audio search and pagination. Results include title, creator, foreign landing page, source/provider, license and license URL, attribution string, duration, media type, direct `url`, and optional `alt_files`. The catalog aggregates metadata from third-party providers rather than operating one uniform music store. This makes Openverse useful for discovery, license-filtered search, and attribution, but not ideal as a single canonical track database.

**Playback: mixed full files and previews**

The response’s `url` is an audio URL, but its semantics are provider-specific. The official examples show a Jamendo storage URL for a music track and a Freesound `hq.mp3` preview for a sound. Some results have no alternate files. Clostel must treat playback capability as `full`, `preview`, or `unknown` based on provider, file type, duration, and a permitted probe; it must not label every Openverse result as a full track.

**Licensing and attribution**

Openverse’s terms say the API aggregates metadata about openly licensed content hosted by third parties; Openverse does not own or control the content, does not verify licensing status, and makes no warranty about the metadata. Clostel is responsible for independently checking the rights and host terms. The API terms require proper attribution to CC-licensed works, compliance with the hosting platform’s terms, and prominent indication that an app uses the Openverse API without implying endorsement. The terms prohibit scraping the catalog, using multiple machines to evade limits, or harming the service. They also reserve the right to charge fees for commercial or heavy use.

**Rate limits and production caveats**

The current documentation describes authenticated `standard` and `enhanced` throttle tiers rather than a stable public numeric anonymous limit. Clostel should read the response headers, back off on throttling, and avoid bulk crawling. The terms permit suspension or termination, prohibit scraping and circumvention, and reserve the right to charge fees for commercial or heavy use.

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

### 7. Audius — open catalog with full streaming, optional key for reads

**Official documentation**

- [Audius developer documentation](https://docs.audius.org/)
- [Audius REST API reference](https://docs.audius.org/api/)
- [Official SDK README and API plans](https://github.com/AudiusProject/apps/blob/main/packages/sdk/README.md)
- [Audius terms update and Open Music License summary](https://blog.audius.co/posts/audius-terms-of-service-update)
- [Official API backend](https://github.com/AudiusProject/api)

**Authentication**

The current official API reference says most read-only endpoints work without credentials and recommends an API key for higher rate limits; writes require an API key and secret. The SDK’s free plan documents a 10 requests/second and 500,000 requests/month allowance. The API key is safe to include in frontend/mobile code; a backend bearer token is for acting on behalf of users and must never be embedded in a mobile app. User login uses OAuth 2.0 Authorization Code with PKCE. Clostel should classify Audius as **optional-key for reads, key-required for writes and higher limits**, not as a fully keyless production integration.

**Search and catalog**

The REST API supports querying and streaming tracks, users, and playlists. The SDK exposes search and discovery for users, tracks, and playlists, plus trending/recommendation and user-curation operations. This is a music-specific catalog rather than an archival metadata dump.

**Playback: full-track stream where permitted**

Audius documents streaming as a first-class API operation, and its open-source content-node documentation describes a streamable MP3 endpoint with range-request support. This is a full-track stream model, not a 30-second preview model. Availability is nevertheless controlled by the track’s current API-access and visibility settings.

**Licensing and attribution**

Audius’ July 2025 terms update says uploaded tracks can default to All Rights Reserved, artists can choose Creative Commons options, and a custom Open Music License governs use of tracks through third-party API applications. API access is on by default unless an artist opts out, and the artist’s visibility and pricing/access settings carry over to the API. Clostel must therefore inspect the current track license/API-access state and the current API Terms/OML; it must not assume that “open network” means unrestricted commercial reuse. Attribution and any OML-specific notice must be preserved per track.

**Rate limits and production caveats**

The official SDK README lists a free plan at 10 requests/second and 500,000 requests/month, with an unlimited plan available by contacting Audius. The current API reference says keys unlock higher limits, and writes require credentials. Audius can change terms and access settings, and the catalog is decentralized/open, so content quality and rights metadata need validation just like any other provider.

**Safe to integrate?**

**Conditionally yes, but not as a keyless provider.** It is a good candidate for an open full-track catalog after Clostel has an API key, a current legal review of the API Terms and OML, and a per-track policy that excludes opt-out or incompatible content.

### 8. MusicBrainz — keyless metadata specialist, not a playback source

**Official documentation**

- [MusicBrainz API](https://musicbrainz.org/doc/MusicBrainz_API)
- [API rate limiting](https://musicbrainz.org/doc/MusicBrainz_API/Rate_Limiting)
- [Database data licensing](https://musicbrainz.org/doc/About/Data_License)
- [Database dumps](https://musicbrainz.org/doc/MusicBrainz_Database/Download)

**Authentication**

The public API does not currently require an API key. Authentication is required for submissions and user-specific information; the documentation describes OAuth, while the older digest flow is deprecated. Clostel’s read-only metadata adapter can remain keyless, but it should send a meaningful User-Agent identifying the app and a contact URL/email.

**Search and catalog**

The API is explicitly aimed at developers of media players, CD rippers, taggers, and other applications requiring music metadata. It exposes artist, recording, release, release-group, work, label, and identifier resources, with search, lookup, browse, aliases, tags, genres, ISRC/ISWC lookups, and relationships. JSON and XML are supported.

**Playback: no audio**

MusicBrainz has no music-file streaming or download endpoint. It can enrich a Clostel item with canonical identifiers, artist/release credits, track positions, and release metadata, but it cannot supply playable audio. The database dump contains metadata, not recordings. Cover art is a separate archive and is not part of the core database.

**Licensing and attribution**

The core database data is CC0, but MusicBrainz explicitly splits the database into core and supplementary data; supplementary data is CC BY-NC-SA 3.0. The live web service is documented as free for non-commercial use, with commercial plans or direct contact available for commercial use. A metadata license is not a license to the underlying sound recording, so Clostel must obtain playback rights separately.

**Rate limits and production caveats**

The API page requires clients to make no more than one call per second and to provide a meaningful User-Agent. The rate-limiting page says excessive per-IP traffic can result in HTTP 503 responses, with a global average limit of 300 requests per second. These limits protect a community service and are not an invitation to mirror the database through the live API.

**Safe to integrate?**

**Conditionally yes as a metadata/canonical-identifier source.** It is a strong enrichment layer for a provider that has its own licensed audio, but it is not a Clostel playback provider and the live API’s non-commercial service terms need a commercial arrangement if the app exceeds that scope.

---

### 9. Apple iTunes Search API — keyless store metadata and promotional previews

**Official documentation**

- [iTunes Search API](https://performance-partners.apple.com/search-api)
- [Archived iTunes Search API overview](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI)
- [Search API overview and legal terms](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/index.html)

**Authentication**

The documented public Search and Lookup endpoints are callable with URL parameters and no API key. This is still a partner/affiliate surface rather than a general-purpose music-license API. The official documentation says promotional content and links are subject to Apple’s terms and that heavier users should consider the Enterprise Partner Feed.

**Search and catalog**

The Search API supports music, artist, album, song, and music-video searches, with country/storefront selection, ID-based lookup, and a 1–200 result limit. Responses include identifiers, names, artwork, prices, explicit-content metadata, store links, track duration, and genre. Results are tied to a particular storefront and can differ by country.

**Playback: promotional preview only**

The `previewUrl` field is a 30-second preview file. Apple’s legal section says preview audio must be used to promote the subject content, be placed near an approved store badge, include “provided courtesy of iTunes” attribution, and be streamed only. It must not be downloaded, saved, cached, synchronized with video, or used for independent entertainment. There is no documented full-track stream or download permission.

**Licensing and attribution**

The promotional-use conditions are part of the API’s legal terms, not merely implementation advice. The Search API is suitable for a store-linked discovery card or approved affiliate flow; it is not suitable for Clostel’s offline library or as a replacement for a licensed music provider.

**Rate limits and production caveats**

Apple documents approximately 20 Search API calls per minute, subject to change, and recommends a small result limit plus caching for large sites. These are approximate service limits, not a guaranteed SLA. Storefront results, availability, prices, and preview behavior can vary by territory.

**Safe to integrate?**

**Conditionally yes for metadata and compliant store promotion only.** Do not treat the presence of `previewUrl` as permission to build a general music player or downloader around it.

---

### 10. Spotify Web API — credentials required, no download path

**Official documentation**

- [Web API getting started](https://developer.spotify.com/documentation/web-api/quick-start)
- [Get Track reference](https://developer.spotify.com/documentation/web-api/reference/get-track)
- [Developer Terms](https://developer.spotify.com/terms)
- [Developer Policy](https://developer.spotify.com/policy)

**Authentication**

Spotify is not keyless. A developer account and registered application produce client credentials; server calls use a client-credentials access token, while user-private features use OAuth. The client secret must stay in a backend. Clostel must not put a backend secret in a Flutter binary or repository.

**Search and catalog**

The Web API provides commercial catalog metadata, search, albums, artists, playlists, recommendations, and related discovery endpoints. It is a mainstream licensed catalog, not an open-license source, and track availability can be market-, product-, or explicit-content-dependent.

**Playback and download restrictions**

The track object’s `preview_url` is a deprecated 30-second preview and can be null; the reference says preview clips cannot be a standalone service. The current Developer Policy allows streaming only through the approved Spotify platform/player path and limits it to Premium subscribers for music sound recordings. It expressly prohibits downloading, saving, or facilitating “stream ripping,” and prohibits mixing or synchronizing Spotify content with other audio or visual media. It also prohibits a product integrated with streams or content from another service.

Those restrictions matter for Clostel: a cross-provider music app should not assume that a Spotify track can be inserted into the same playback queue as a Jamendo, Audius, or open catalog item. A Spotify integration would need Spotify’s written approval and a narrowly approved integration design.

**Licensing and attribution**

Spotify content must be attributed, and metadata, cover art, and preview clips must link back to the applicable Spotify content. Local caching is limited to narrowly defined temporary metadata/cover art and, for eligible Premium users, time-limited conditional downloads under Spotify’s terms. Commercial use is restricted except for the limited non-streaming cases in the policy.

**Rate limits and production caveats**

Spotify’s current policy says quotas and restrictions may apply and that additional quota requires an application and compliance review; the cited documents do not provide a stable public per-endpoint number. Spotify can monitor usage, modify the platform, or revoke credentials. A quota extension is not permission to add download or cross-service functionality.

**Safe to integrate?**

**Not as Clostel’s download or cross-provider playback backend.** It may be a candidate for a separate, Spotify-approved metadata or official-player integration only after a current terms review and explicit agreement on the product model.

---

### 11. YouTube Data API — key-required metadata, official playback only

**Official documentation**

- [YouTube Data API overview](https://developers.google.com/youtube/v3/getting-started)
- [API reference and authentication](https://developers.google.com/youtube/v3/docs)
- [Quota and compliance audits](https://developers.google.com/youtube/v3/guides/quota_and_compliance_audits)
- [Developer Policies](https://developers.google.com/youtube/terms/developer-policies)
- [API Services Terms of Service](https://developers.google.com/youtube/terms/api-services-terms-of-service)
- [IFrame Player API](https://developers.google.com/youtube/iframe_api_reference)

**Authentication**

The Data API requires a Google Cloud project, API enablement, and an API key even for public reads. OAuth 2.0 is required for user-authorized data and write operations. The IFrame Player API is a separate official player surface; the developer policies say it does not require user authorization, but an application still must follow YouTube’s identity, branding, privacy, and minimum-functionality rules.

**Search and catalog**

The Data API exposes public video, channel, playlist, search, and statistics metadata. It is a video catalog API, not a music metadata database with a stable mapping from a video to a particular licensed sound recording. Clostel should not infer that a video title or description is an authoritative track identity.

**Playback and download**

The official route is to let YouTube play the content through its approved player/embed or platform integration. The Data API does not grant a general full-track audio URL. YouTube’s Developer Policies prohibit downloading, importing, backing up, caching, or storing audiovisual content without prior written approval, and prohibit making it available for offline playback. The API Terms also say that no rights are granted to reproduce or distribute audiovisual content except through the API as allowed by the agreement.

**Licensing and attribution**

YouTube API data includes music, sounds, and other audiovisual material, but the API client receives no ownership or unrestricted content license. API clients must display YouTube terms/privacy information, use YouTube branding where required, avoid undocumented APIs and scraping, and follow storage/deletion rules for authorized and non-authorized data. Clostel should treat the source video and the underlying recording as separate rights and identity problems.

**Rate limits and production caveats**

The current quota documentation gives a default allocation of 100 `search.list` calls, 100 `videos.insert` calls, and 10,000 units per day for other endpoints, subject to change. Additional quota requires a compliance audit. Quota units are not permission to extract or mirror content, and a mobile client must be able to follow API changes and credential/data-deletion requirements.

**Safe to integrate?**

**Conditionally yes through the official YouTube player/API path only.** It is not a general-purpose audio download provider for Clostel, and using an extractor to obtain media would move outside the documented API model.

---

### 12. yt-dlp — useful developer-time tool, not a production catalog API

**Official documentation**

- [yt-dlp official repository and README](https://github.com/yt-dlp/yt-dlp)
- [Embedding yt-dlp](https://github.com/yt-dlp/yt-dlp#embedding-yt-dlp)
- [Supported sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md)
- [yt-dlp license](https://github.com/yt-dlp/yt-dlp/blob/master/LICENSE)
- [Third-party licenses](https://github.com/yt-dlp/yt-dlp/blob/master/THIRD_PARTY_LICENSES.txt)

**What it is**

yt-dlp describes itself as a feature-rich command-line audio/video downloader for thousands of sites. It is a Python program, not a Dart package and not a provider-neutral catalog API. Its README says it should be callable from other programming languages and recommends stable machine-readable options such as `--print` and `--dump-single-json` rather than parsing ordinary stdout; it also documents a Python embedding API.

A conservative integration could use yt-dlp for a **developer-time import or metadata inspection** for a URL that Clostel owns or has explicit permission to process. `--dump-single-json`/`--simulate` can provide extractor metadata without downloading media. That is materially different from making yt-dlp Clostel’s runtime catalog: extractor output is site-specific, may contain transient URLs, and is not a normalized rights record.

**Audio and download support**

yt-dlp can select and download audio-only formats, and its presets can invoke audio extraction/conversion. It may require `ffmpeg`/`ffprobe`; the current README also says full YouTube support requires `yt-dlp-ejs` and a supported JavaScript runtime. A media “success” therefore says only that the tool obtained bytes; it does not say Clostel has the right to keep, redistribute, cache, or play those bytes.

**Target-site terms are the controlling constraint**

For YouTube, the official Terms of Service say that content may be viewed or listened to for personal, non-commercial use, and prohibit reproduction, download, distribution, transmission, display, or other use except as expressly authorized or with prior written permission from YouTube and applicable rights holders. They also prohibit automated access except for permitted public search engines or with prior written permission. The current YouTube API Developer Policies separately prohibit undocumented APIs, scraping, downloading/caching/storing audiovisual content without prior written approval, and offline playback.

Therefore, using yt-dlp to bypass a provider’s key, preview limit, geo restriction, DRM, authentication, or rate limit is not an acceptable Clostel implementation. The software’s Unlicense also does not grant rights to YouTube or other site content. The repository notes that bundled release binaries include GPLv3+ and other third-party components; that is a software-distribution issue distinct from media licensing.

**Operational risks**

- **Brittleness:** site extractors change; the README says stable releases can be stale and recommends nightly for regular users. A pinned version is more reproducible but will still need monitored updates.
- **Packaging:** a Flutter app would need a platform-specific executable or Python runtime plus ffmpeg and a JavaScript runtime, with process isolation, paths, permissions, updates, and cleanup handled per platform. This is an external-tool integration, not a normal Dart dependency.
- **No central rate limit:** yt-dlp has no Clostel-wide quota; it makes requests to the target site. `--sleep-requests`, retries, and rate limits can reduce pressure but do not grant permission and do not prevent blocks or takedowns.
- **Supply chain and security:** pin the tool, obtain official release artifacts, verify the published checksums/signatures, and do not allow arbitrary remote components. The README documents that remote components are disabled by default and warns that updates from other repositories are not verified.
- **Data handling:** URLs and extractor output are untrusted input. Clostel must validate URL schemes/hosts, isolate subprocesses, cap concurrency and output, and avoid passing user-controlled strings through a shell.

**Safe to integrate?**

**Not as a production fallback, arbitrary-URL downloader, or cross-provider playback source.** It is defensible only for controlled development/import workflows where Clostel has written permission, the target site’s terms allow the action, and the resulting media license is recorded. Legal review should happen before shipping any yt-dlp-based user flow.

## Recommendation for Clostel’s provider order

### Immediate keyless prototype order

1. **ccMixter** — first choice for keyless full-track experimentation. Use the public read-only Query API, normalize the JSON file list, require an explicit license record, expose no download/offline action, and keep traffic low. Treat the beta API as experimental.
2. **Internet Archive** — second choice for archival, public-domain, historical, and field-recording material. Use Advanced Search plus Metadata Read, require per-item rights validation, and send a descriptive User-Agent.
3. **Openverse** — third choice for broad discovery, search suggestions, and attribution. Use it to find candidate works, then follow the foreign landing page/provider and verify the actual file; do not assume every `url` is a full track.
4. **Wikimedia Commons** — fourth choice for supplementary freely licensed audio and public-domain material. It is not music-specific, so keep it separate from the main catalog ranking.
5. **MusicBrainz** — fifth choice for canonical metadata and identifier enrichment, not playback. Respect the one-request-per-second guidance and distinguish CC0 core data from CC BY-NC-SA supplementary data.
6. **Apple iTunes Search API** — optional store-linked metadata/affiliate discovery only. Keep its 30-second preview behind Apple’s promotional-use and no-cache rules.

### Commercial production order

1. **Jamendo, after a commercial/API agreement** — best documented structured music catalog with full-track streaming, search/discovery, and explicit download controls. It is not keyless.
2. **Audius, after current API Terms/OML review** — strong open full-track streaming candidate; use the optional key for higher limits and keep per-track API-access and license checks. It is not fully keyless.
3. **MusicBrainz for metadata enrichment** — use canonical IDs/credits alongside an audio provider, subject to the non-commercial web-service terms or a commercial arrangement.
4. **ccMixter and Internet Archive as supplemental providers** — use only with strict per-item/per-track rights checks, conservative request rates, and a fallback when a file is removed or unavailable.
5. **Openverse as an attribution/discovery layer** — do not make it the canonical playback provider unless each result is promoted through its underlying source and the source’s terms are accepted.
6. **Wikimedia Commons as a supplemental source**, not the default music catalog.
7. **Apple iTunes Search API as a compliant store-promotion surface** — not a general music playback or offline source.
8. **Spotify and YouTube excluded from Clostel’s download/cross-provider backend** — they may support separately approved official metadata/player integrations, but their current policies do not authorize extraction, downloading, or mixing with other providers.
9. **Deezer excluded from production** — its public API is preview-oriented and its current developer terms are non-commercial/private-use and prohibit offline storage. Do not use scraping, full-track URL extraction, DRM bypass, or auth bypass.
10. **yt-dlp excluded from the production catalog/download path** — reserve any use for controlled, permissioned development/import work only.

## Implementation guardrails for Clostel

- Keep provider adapters behind the project’s provider-neutral catalog/playback interfaces; do not leak provider URLs or response shapes into the domain.
- Normalize a `playbackKind` value such as `full`, `preview`, or `unknown`; never infer “full” solely from the existence of a URL.
- Preserve `provider`, `providerTrackId`, source/landing URL, creator, license name/version/URL, attribution text, and the timestamp when rights were checked.
- Apply a rights policy before returning a result to a user. For CC catalogs, exclude NC/ND licenses when the product use requires commercial or remix rights; do not treat “Creative Commons” as one blanket permission.
- Never implement offline downloads for Deezer, Jamendo, Spotify, YouTube, or yt-dlp-extracted media without explicit written permission. Apple’s preview terms expressly prohibit download/save/cache, and Openverse, ccMixter, IA, Commons, MusicBrainz, and Audius also need their own terms/track-level checks.
- Use descriptive User-Agent headers, bounded concurrency, caching, backoff, and `429`/`Retry-After` handling for public/community services. MusicBrainz’s live API is limited to one request per second; Openverse’s current tiers and limits must be read from response headers.
- Treat all API responses and extractor output as untrusted input, as required by the repository rules. Do not follow arbitrary URLs from metadata without validating scheme, host, content type, and licensing context.
- Do not scrape provider websites, reverse-engineer protected endpoints, reuse test credentials, or bypass authentication, geo restrictions, DRM, preview limits, or rate limits. yt-dlp is not an exception to these rules.
- If yt-dlp is used for a controlled development/import workflow, pin and verify the tool, isolate it as a subprocess, restrict URLs and concurrency, disable uncontrolled remote components, and never treat a successful extraction as a rights grant.

## Source index

- [MusicBrainz API](https://musicbrainz.org/doc/MusicBrainz_API), [rate limiting](https://musicbrainz.org/doc/MusicBrainz_API/Rate_Limiting), [data licensing](https://musicbrainz.org/doc/About/Data_License), [dumps](https://musicbrainz.org/doc/MusicBrainz_Database/Download)
- [Apple iTunes Search API](https://performance-partners.apple.com/search-api), [overview/legal terms](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/index.html)
- [Spotify Web API quickstart](https://developer.spotify.com/documentation/web-api/quick-start), [track reference](https://developer.spotify.com/documentation/web-api/reference/get-track), [Developer Terms](https://developer.spotify.com/terms), [Developer Policy](https://developer.spotify.com/policy)
- [YouTube Data API overview](https://developers.google.com/youtube/v3/getting-started), [API reference](https://developers.google.com/youtube/v3/docs), [quota](https://developers.google.com/youtube/v3/guides/quota_and_compliance_audits), [Developer Policies](https://developers.google.com/youtube/terms/developer-policies), [API Terms](https://developers.google.com/youtube/terms/api-services-terms-of-service), [YouTube Terms](https://www.youtube.com/t/terms), [IFrame Player](https://developers.google.com/youtube/iframe_api_reference)
- [yt-dlp official repository/README](https://github.com/yt-dlp/yt-dlp), [embedding](https://github.com/yt-dlp/yt-dlp#embedding-yt-dlp), [supported sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md), [license](https://github.com/yt-dlp/yt-dlp/blob/master/LICENSE), [third-party licenses](https://github.com/yt-dlp/yt-dlp/blob/master/THIRD_PARTY_LICENSES.txt)
- [Deezer API](https://developers.deezer.com/api), [guidelines](https://developers.deezer.com/guidelines), [terms](https://developers.deezer.com/termsofuse)
- [Jamendo API docs](https://developer.jamendo.com/v3.0/docs), [authentication](https://developer.jamendo.com/v3.0/authentication), [tracks](https://developer.jamendo.com/v3.0/tracks), [file/stream](https://developer.jamendo.com/v3.0/tracks/file), [terms](https://devportal.jamendo.com/api_terms_of_use)
- [Audius docs](https://docs.audius.org/), [API reference](https://docs.audius.org/api/), [SDK/API plans](https://github.com/AudiusProject/apps/blob/main/packages/sdk/README.md), [terms update](https://blog.audius.co/posts/audius-terms-of-service-update)
- [Internet Archive Developer Portal](https://archive.org/developers/), [Advanced Search](https://archive.org/advancedsearch.php), [Metadata Read](https://archive.org/developers/md-read.html), [metadata schema](https://archive.org/developers/metadata-schema/index.html), [automated access](https://archive.org/developers/bots.html)
- [ccMixter Query API](https://ccmixter.org/query-api), [terms](https://ccmixter.org/terms), [read-only API discussion](https://ccmixter.org/thread/3254)
- [Openverse API](https://api.openverse.org/), [audio endpoint](https://api.openverse.org/v1/audio/), [throttling](https://docs.openverse.org/api/reference/authentication_and_throttling.html), [terms](https://wordpress.github.io/openverse-api/terms_of_service.html)
- [Wikimedia Commons API](https://commons.wikimedia.org/wiki/Commons:API), [MediaWiki API etiquette](https://www.mediawiki.org/wiki/API:Etiquette), [Commons licensing](https://commons.wikimedia.org/wiki/Commons:Licensing), [Foundation terms](https://foundation.wikimedia.org/wiki/Policy:Terms_of_Use)

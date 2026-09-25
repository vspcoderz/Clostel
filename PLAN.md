# Clostel MVP

## Goal

Build a playable cross-platform music-app slice with a distinctive Clostel interface: browse real music, search, play a track, manage a queue, and see the library.

## Approach

- Use Flutter for Android, iOS, Windows, macOS, and Linux.
- Keep the catalog behind a provider-neutral contract.
- Make offline listening the default: import user-owned audio files through a native file picker, keep them in the local library, and play them without an account or network. Online Jamendo/Deezer discovery remains optional.
- Centralize playback state in a controller; keep widgets presentational.
- Use Flutter's built-in Material 3 components for Android/Linux/Windows and `flutter_liquid_glass_kit` components for iOS/macOS. Glass is limited to functional surfaces: navigation, search, primary actions, and the player dock. Content cards stay standard Material surfaces so the interface remains readable.
- Default to a warm white Material appearance with dark mode retained as an alternate. Bundle Funnel Display and Open Sans locally: Funnel Display for display/heading typography, Open Sans for body text and controls.
- Keep the supplied Clostel palette: vibrant coral (`#EB5E55`) for primary actions, graphite (`#3A3335`) for the base, raspberry red (`#D81E5B`) for secondary emphasis, papaya whip (`#FDF0D5`) for warm light surfaces, and ash grey (`#C6D8D3`) for secondary text. Use a light background gradient so glass remains legible.

## Files touched

- Flutter project scaffold and platform runner files.
- `lib/core/` for models, theme, provider contracts, the Deezer/Jamendo adapters, and local-file import.
- `lib/features/home/` for the main browsing and player experience plus adaptive Material/Liquid Glass components and settings.
- `assets/fonts/` for bundled Funnel Display and Open Sans fonts.
- `test/` for domain, catalog parsing, and controller behavior.
- `AGENTS.md` for repository conventions.

## Verification steps

1. `flutter analyze` passes.
2. `flutter test` passes.
3. The app launches on the available Flutter target.
4. Real catalog search returns normalized tracks and preview playback is clearly labeled.
5. Search, play/pause, queue, and library interactions are exercised manually or with tests.
6. No secrets or unlicensed catalog URLs are committed.

## Status

In progress — visual refresh, real catalog integration, and the requested UI/player expansion.

## UI and BhariyaMusic integration plan

### Goal

Upgrade Clostel into a polished, local-first music player with a full Now Playing experience, durable state, stronger queue/search/settings surfaces, and an optional provider-neutral BhariyaMusic adapter without introducing unsafe or unlawful default behavior.

### Approach

- Implement the UI in phases so the app remains buildable: player foundation first, then navigation/search/library/settings, then discovery polish and accessibility.
- Keep the existing `PlayerController` as the single playback owner and add explicit playback state, queue actions, persistence seams, and background/media integration behind service interfaces.
- Preserve Material 3 on Android/Linux/Windows and Liquid Glass only for functional layers on Apple platforms.
- Treat the desktop yt-dlp adapter as an explicit, user-operated integration. It may auto-discover a locally installed yt-dlp executable on Linux/macOS/Windows, with `YT_DLP_PATH` as an override and `YT_DLP_DISABLED=true` as an opt-out. fzf is not embedded in the Flutter UI; Flutter provides the selection surface.
- Treat BhariyaMusic as an optional external provider configured by environment, not a bundled production dependency. Do not hard-code its DDNS endpoint.
- Do not enable or advertise audio extraction/download from YouTube or Spotify by default. If the provider is enabled, validate every URL and response and clearly mark provenance/playback status.

### Files touched

- `PLAN.md`
- `lib/app.dart`
- `lib/main.dart`
- `lib/core/models/`
- `lib/core/services/`
- `lib/core/data/`
- `lib/features/home/`
- `lib/features/player/`
- `test/`
- `pubspec.yaml` only if a concrete platform capability requires a new dependency.

### Verification steps

1. `flutter analyze` passes.
2. `flutter test` passes.
3. Existing catalog and playback tests remain green.
4. Provider response parsing, URL validation, and disabled-by-default behavior are tested.
5. Player state transitions, queue actions, persistence, and theme selection are tested.
6. Responsive layouts are checked at phone, tablet, and desktop widths.
7. No secrets, cookies, tokens, or unlicensed catalog endpoints are committed.
8. The final integration is reviewed for security and licensing before being enabled.

### Status

Implementation in progress — user selected explicit opt-in BhariyaMusic audio. The external repository remains unvendored and must stay behind environment configuration until its rights and security review is documented.

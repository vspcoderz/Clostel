# Clostel MVP

## Goal

Build a playable cross-platform music-app slice with a distinctive Clostel interface: browse real music, search, play a track, manage a queue, and see the library.

## Approach

- Use Flutter for Android, iOS, Windows, macOS, and Linux.
- Keep the catalog behind a provider-neutral contract.
- Use Deezer's public catalog API for real global tracks and preview playback, with the local demo catalog as an offline fallback. Preview playback must be labeled honestly; full-track streaming remains a future authenticated provider integration.
- Centralize playback state in a controller; keep widgets presentational.
- Use Flutter's built-in Material 3 components for Android/Linux/Windows and `flutter_liquid_glass_kit` components for iOS/macOS. Glass is limited to functional surfaces: navigation, search, primary actions, and the player dock. Content cards stay standard Material surfaces so the interface remains readable.
- Default to a warm white Material appearance with dark mode retained as an alternate. Bundle Funnel Display and Open Sans locally: Funnel Display for display/heading typography, Open Sans for body text and controls.
- Keep the supplied Clostel palette: vibrant coral (`#EB5E55`) for primary actions, graphite (`#3A3335`) for the base, raspberry red (`#D81E5B`) for secondary emphasis, papaya whip (`#FDF0D5`) for warm light surfaces, and ash grey (`#C6D8D3`) for secondary text. Use a light background gradient so glass remains legible.

## Files touched

- Flutter project scaffold and platform runner files.
- `lib/core/` for models, theme, provider contracts, and the Deezer catalog adapter.
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

In progress — visual refresh and real catalog integration.

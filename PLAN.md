# Clostel MVP

## Goal

Build a playable cross-platform music-app slice with a distinctive Clostel interface: browse music, search, play a track, manage a queue, and see the library.

## Approach

- Use Flutter for Android, iOS, Windows, macOS, and Linux.
- Keep the catalog behind a provider-neutral contract.
- Use a local demo catalog for deterministic development and tests until a licensed streaming provider and credentials are selected.
- Centralize playback state in a controller; keep widgets presentational.
- Use Flutter's built-in Material 3 components for Android/Linux/Windows and `flutter_liquid_glass_kit` components for iOS/macOS. Glass is limited to functional surfaces: navigation, search, primary actions, and the player dock. Content cards stay standard Material surfaces so the interface remains readable.
- Use the supplied Clostel palette: vibrant coral (`#EB5E55`) for primary actions, graphite (`#3A3335`) for the base, raspberry red (`#D81E5B`) for secondary emphasis, papaya whip (`#FDF0D5`) for primary text, and ash grey (`#C6D8D3`) for secondary text. Use a subdued graphite-to-coral/raspberry background gradient so glass remains legible.

## Files touched

- Flutter project scaffold and platform runner files.
- `lib/core/` for models, theme, and provider contracts.
- `lib/features/home/` for the main browsing and player experience plus adaptive Material/Liquid Glass components.
- `test/` for domain and controller behavior.
- `AGENTS.md` for repository conventions.

## Verification steps

1. `flutter analyze` passes.
2. `flutter test` passes.
3. The app launches on the available Flutter target.
4. Search, play/pause, queue, and library interactions are exercised manually or with tests.
5. No secrets or unlicensed catalog URLs are committed.

## Status

In progress.

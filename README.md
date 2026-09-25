# Clostel

Clostel is a cross-platform music player for Android, iOS, Windows, macOS, and Linux.

## Visual system

The Clostel palette is intentional: vibrant coral (`#EB5E55`) for primary actions, graphite (`#3A3335`) for the base, raspberry red (`#D81E5B`) for secondary emphasis, papaya whip (`#FDF0D5`) for primary text, and ash grey (`#C6D8D3`) for secondary text. The app uses a subdued multi-stop gradient behind the functional glass layer so contrast survives the blur.

## Current slice

The first slice is a playable MVP shell with:

- Responsive desktop and mobile layouts
- Material 3 navigation and content components on Android/Linux/Windows
- Native Liquid Glass navigation, search, buttons, and player surfaces on iOS/macOS via `flutter_liquid_glass_kit`
- Funnel Display headings and Open Sans body typography, bundled locally
- Discover/search surface
- Real global music discovery through Deezer previews and optional Jamendo full Creative Commons tracks
- Local demo catalog fallback for offline development
- Local audio import for user-owned files and offline listening
- Preview playback is clearly labeled; full-track Jamendo playback requires a production client ID and license review
- Discord Rich Presence on desktop using the bundled application ID, with a `DISCORD_APPLICATION_ID` build override for other environments
- Settings toggle for Discord Rich Presence
- Original generated demo audio assets for the offline fallback

The demo catalog is not a production music source. The next integration boundary is a licensed streaming provider with real authentication and playback authorization.

## Run

Install Flutter 3.27+ (Dart 3.6+), then:

```bash
./tool/bootstrap.sh
flutter run
```

To enable Jamendo full-track discovery in a configured environment:

```bash
flutter run -d linux \
  --dart-define=JAMENDO_CLIENT_ID=your_jamendo_client_id
```

Jamendo requires a client ID even for read requests. Clostel does not ship a test or production client ID in source.

Discord Rich Presence uses the bundled Clostel application ID. To override it:

```bash
flutter run -d linux \
  --dart-define=DISCORD_APPLICATION_ID=your_application_id
```

The application ID is not a secret. Never put Discord tokens or other credentials in this repository.

Verify:

```bash
flutter analyze
flutter test
```

## Structure

- `lib/core/models` — domain models
- `lib/core/services` — catalog and playback contracts plus platform playback adapter
- `lib/features/home` — responsive Clostel shell, screens, and adaptive Material/Liquid Glass components
- `lib/features/player` — playback state controller
- `test` — catalog and controller tests
- `assets/audio` — original local demo audio, not a third-party catalog

No API keys belong in this repository. Streaming credentials belong in platform-secure storage and environment configuration.

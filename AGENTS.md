# Clostel Agent Rules

## Project

Clostel is a cross-platform music app for Android, iOS, Windows, macOS, and Linux.

## Stack

- Flutter and Dart for the application.
- Material 3 as the base design system on Android, Linux, and Windows; product-specific tokens live in the app theme.
- `flutter_liquid_glass_kit` is the Apple-platform component layer for iOS and macOS. Use its navigation, search, button, and player components rather than hand-rolling equivalents.
- Provider-neutral interfaces for music catalogs, playback, and authentication.
- Local demo catalog is allowed for development and UI tests only. It is not a production music source.

## Architecture

- Keep domain models independent of Flutter widgets and platform plugins.
- Put provider/network implementations behind interfaces in the data layer.
- Never hard-code API keys, tokens, or secrets. Use platform-secure storage and environment configuration.
- Treat external API responses as untrusted input and validate/normalize them before entering the domain.
- Keep playback state in one controller; widgets should not own audio state.
- Keep Liquid Glass on functional layers only: navigation, search, primary actions, and player chrome. Use standard Material cards and list components for content.
- Do not add Rust/Cargo-based native plugins to this project. Keep Discord Rich Presence on the pure Dart `discord_rich_presence` path.
- Prefer feature-first folders: `lib/features/...`, with shared code in `lib/core/...`.

## Verification

Run these checks from the project root before calling work complete:

```bash
flutter analyze
flutter test
flutter build <platform>   # when platform packaging is in scope
```

Add or update tests for domain logic, provider normalization, and playback state transitions. UI tests should cover critical user flows rather than pixel details.

## Scope discipline

Implement the requested slice. Do not add speculative integrations, duplicated abstractions, or dependencies without a concrete need. A new dependency must solve a real platform or product problem and be listed in the relevant plan.

#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is required. Install Flutter 3.27+ before bootstrapping Clostel." >&2
  exit 1
fi

flutter create --platforms=android,ios,linux,macos,windows --project-name clostel .
flutter pub get

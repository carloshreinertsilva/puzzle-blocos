#!/usr/bin/env bash
# Builds the web version on Vercel. Vercel's image has no Flutter, so this
# fetches the pinned version first. Set in vercel.json as the build command.
set -euo pipefail

FLUTTER_VERSION=3.47.7
FLUTTER_DIR="$HOME/flutter-$FLUTTER_VERSION"

command -v unzip >/dev/null || dnf install -y unzip >/dev/null

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

flutter config --no-analytics >/dev/null
flutter --version
flutter pub get
flutter build web --release --no-web-resources-cdn

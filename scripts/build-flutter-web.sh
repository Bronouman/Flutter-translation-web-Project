#!/usr/bin/env bash
set -euo pipefail

FLUTTER_DIR="${FLUTTER_DIR:-/tmp/flutter}"
if [[ ! -x "$FLUTTER_DIR/bin/flutter" ]]; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
flutter config --no-analytics
flutter pub get --directory=lingo_app
flutter build web --release --no-pub --project-directory=lingo_app

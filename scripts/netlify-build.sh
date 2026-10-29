#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="3.47.7"
FLUTTER_DIR="${TMPDIR:-/tmp}/gastosclaros-flutter-${FLUTTER_VERSION}"

if command -v flutter >/dev/null 2>&1; then
  FLUTTER_BIN="$(command -v flutter)"
else
  if [ ! -x "${FLUTTER_DIR}/bin/flutter" ]; then
    git clone --depth 1 --branch "${FLUTTER_VERSION}" \
      https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
  fi
  FLUTTER_BIN="${FLUTTER_DIR}/bin/flutter"
fi

npm ci --prefix backend --no-audit --no-fund
"${FLUTTER_BIN}" config --enable-web
(cd frontend && "${FLUTTER_BIN}" pub get && "${FLUTTER_BIN}" build web --release --pwa-strategy=none --no-wasm-dry-run)

# One version per deploy. The worker replaces older GastosClaros caches on update.
BUILD_HASH="$(sha256sum frontend/build/web/main.dart.js | cut -c1-12)"
sed "s/__BUILD_VERSION__/${BUILD_HASH}/g" frontend/web/sw.js \
  > frontend/build/web/sw.js

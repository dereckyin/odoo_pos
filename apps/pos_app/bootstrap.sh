#!/usr/bin/env bash
# Bootstraps the Flutter POS app for first-time checkout.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"

cd "$HERE"

# Add platform folders (idempotent: --platforms re-uses existing where present)
echo "→ flutter create platform folders"
flutter create --platforms=macos,windows,linux,android,ios . >/dev/null

cd "$ROOT"

# Bootstrap monorepo
if ! command -v melos >/dev/null 2>&1; then
  echo "→ activating melos"
  dart pub global activate melos
fi
echo "→ melos bootstrap"
melos bootstrap

# Codegen
cd "$HERE"
echo "→ build_runner (drift / freezed / l10n)"
flutter pub run build_runner build --delete-conflicting-outputs

echo "✓ bootstrap done. Run:  flutter run -d macos  (or windows / linux / android)"

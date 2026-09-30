#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_PATH:-$(command -v godot || true)}"
[[ -n "$GODOT_BIN" ]] || { echo 'Godot 4.7.2 not found. Set GODOT_PATH.' >&2; exit 1; }
"$GODOT_BIN" --version | grep -q '^4\.7\.2' || { echo 'Godot 4.7.2 required.' >&2; exit 1; }
cd "$PROJECT_ROOT"
"$GODOT_BIN" --headless --path . --editor --quit
"$GODOT_BIN" --headless --path . --script res://tests/run_all.gd
"$GODOT_BIN" --headless --path . --script res://tools/level_baker/bake_campaign.gd
mkdir -p build
if [[ -f "$PROJECT_ROOT/android/build/src/main/assets/project.binary" ]]; then
  [[ ! -L "$PROJECT_ROOT/android/build/src/main/assets" ]] || { echo 'Unsafe generated-assets symlink.' >&2; exit 1; }
  mv "$PROJECT_ROOT/android/build/src/main/assets" "$PROJECT_ROOT/build/android-assets-backup-$(date -u +%Y%m%d-%H%M%S)"
fi
GRADLE_OPTS="${GRADLE_OPTS:-} -Dorg.gradle.daemon=false" "$GODOT_BIN" --headless --path . --export-debug 'Android Debug' build/lost-and-sorted-debug.apk --quit
test -s build/lost-and-sorted-debug.apk
echo 'APK ready: build/lost-and-sorted-debug.apk'


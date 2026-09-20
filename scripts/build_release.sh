#!/usr/bin/env bash
set -euo pipefail
: "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?Missing signing keystore path}"
: "${GODOT_ANDROID_KEYSTORE_RELEASE_USER:?Missing signing user}"
: "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:?Missing signing password}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_PATH:-$(command -v godot || true)}"
[[ -n "$GODOT_BIN" ]] || { echo 'Godot 4.7.2 not found. Set GODOT_PATH.' >&2; exit 1; }
"$GODOT_BIN" --version | grep -q '^4\.7\.2' || { echo 'Godot 4.7.2 required.' >&2; exit 1; }
cd "$PROJECT_ROOT"
"$GODOT_BIN" --headless --path . --script res://tests/run_all.gd
"$GODOT_BIN" --headless --path . --script res://tools/level_baker/bake_campaign.gd
mkdir -p build
"$GODOT_BIN" --headless --path . --export-release 'Android Release' build/lost-and-sorted-release.aab
test -s build/lost-and-sorted-release.aab
echo 'Signed AAB ready: build/lost-and-sorted-release.aab'


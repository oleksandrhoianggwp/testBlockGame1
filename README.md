# Lost & Sorted

Production-oriented, offline-first layered sorting puzzle for Android, built with Godot 4.7.2 and typed GDScript. Tap accessible luggage, group three matching destinations in a seven-slot tray, and renovate five increasingly unusual airport terminals.

![Gameplay](store/screenshots/gameplay.png)

## Included in version 1.0

- 150 fixed-seed campaign levels across five worlds and 15 layout families.
- Independent solver validation for every shipped level; no booster is required.
- Mystery luggage, locks and keys, move-based priority flights.
- Undo snapshots, solvability-preserving Shuffle and one-per-level Extra Slot.
- Campaign progression, three-star results, scores, coins and 90 airport upgrade stages.
- Deterministic offline Daily Challenge, seven-day streak and Endless mode.
- English and Ukrainian localization, adjustable text, reduced motion, sound and haptics.
- Atomic versioned local saves with backup recovery.
- Original SVG art and reproducible procedural WAV effects; no network-loaded assets.
- Mock rewarded/interstitial states on desktop and an optional Android AdMob adapter.

## Screenshots

Actual captures generated from the Godot desktop build are in [`store/screenshots`](store/screenshots): Home, Campaign, Gameplay, Airport and Daily.

## Architecture

The authoritative state is in `core/gameplay/game_state.gd`. Presentation sends item IDs to it and never decides accessibility. `core/generation` constructs each board from a known valid triplet sequence. `core/solver` independently searches that state using the same domain rules. `data/campaign` is immutable baked content; runtime does not regenerate campaign levels.

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md), and [`docs/DECISIONS.md`](docs/DECISIONS.md).

## Repository map

```text
app/                    boot scene and responsive application UI
core/gameplay/          serializable rules and snapshots
core/generation/        deterministic level construction
core/solver/            rendering-independent DFS solver
services/               save, audio, haptics, ads, QA analytics
data/campaign/          150 baked JSON levels and report
data/configs/           economy, version and destination definitions
data/localization/      English/Ukrainian translation source
assets/                 original SVG and WAV assets
tools/                  level baker, stress and asset generation
tests/                  headless unit/integration runner
docs/                   architecture, design, QA and release notes
store/                  listing copy, policy, art and screenshots
scripts/                Windows and Unix build entry points
```

## Run

Install Godot 4.7.2 stable, then:

```powershell
godot --path . --editor
godot --path .
```

The renderer is Compatibility and the reference viewport is 432×768 portrait. Desktop play, headless tests and all core modes work without Android tooling or an ad plugin.

## Test and validate

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/run_all.gd
godot --headless --path . --script res://tools/level_baker/bake_campaign.gd
godot --headless --path . --script res://tools/level_baker/stress_generation.gd
godot --headless --path . --quit-after 120
```

The baker rewrites `data/campaign/level_001.json` through `level_150.json`, `index.json`, and `validation_report.txt`. Campaign changes must commit all these files together.

Regenerate original assets with:

```powershell
godot --headless --path . --script res://tools/asset_generation/generate_assets.gd
```

## Android debug APK

Requirements: Godot 4.7.2 export templates, OpenJDK 17, Android SDK platform/API 36, matching Build Tools, and the Godot Gradle build template. Configure Java SDK and Android SDK paths in Godot editor settings, then:

```powershell
.\scripts\build_debug.ps1
```

or:

```bash
./scripts/build_debug.sh
```

Output is `build/lost-and-sorted-debug.apk`. The configured minimum SDK is 24; target SDK is 36. This balances broad Android coverage with modern Gradle/plugin support.

## Release AAB and signing

The release scripts require all three environment values and refuse to continue without them:

```text
GODOT_ANDROID_KEYSTORE_RELEASE_PATH
GODOT_ANDROID_KEYSTORE_RELEASE_USER
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
```

Then run `scripts/build_release.ps1` or `scripts/build_release.sh`. Output is `build/lost-and-sorted-release.aab`. Keystores, local SDK paths and credentials are ignored by Git.

Before Play submission, replace the development-safe package ID `com.lostandsorted.game` with the publisher-owned final ID and complete [`docs/RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md).

## Optional AdMob

Core gameplay ships with ads disabled and needs no plugin. The documented compatible integration is `godot-sdk-integrations/godot-admob` v7.0, pinned because that release explicitly supports Godot 4.7. Install its Android artifact into the Gradle build, configure UMP consent and production IDs outside version control, then route the autoload to `AndroidAdMobService`. Google test unit IDs are present only in the adapter for debug use. Do not enable production ads before consent, test-device, Data Safety and privacy reviews.

## Saves and localization

Godot stores the profile under `user://lost_sorted_save.json` with a backup beside it. On Windows this maps under `%APPDATA%\Godot\app_userdata\Lost & Sorted`; Android uses app-private storage. Translation source is `data/localization/strings.csv`. Switch language at runtime in Settings.

## Troubleshooting

- `godot` not found: set `GODOT_PATH` to the Godot 4.7.2 executable.
- Missing Android template: install the Godot 4.7.2 export templates and the project Gradle build template.
- Android export fails before Gradle: confirm OpenJDK 17 and SDK platform 36 paths in editor settings.
- Release script refuses to run: configure all signing environment values; it intentionally cannot emit an unsigned “release success”.
- Ads unavailable: expected on desktop, offline, or without the optional pinned plugin. Gameplay is unaffected.
- Corrupt save: the loader tries `.backup.json`; removing both files creates a clean 200-coin profile.

## License and notices

Project-specific source and original assets are provided for this repository. Godot is MIT licensed. No third-party runtime package is vendored. See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).


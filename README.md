# Lost & Sorted — 2.1.0
Offline luggage sorting puzzle for Godot 4.7.2 and Android. Match three flight
tags on a seven-slot conveyor, travel through 75 stages, and grow one airport.

![Gameplay](store/screenshots/gameplay.png)

## Current version
- Original illustrated airport atmosphere, connected clickable isometric hub,
  28 building stages, suitcase branding, six distinct luggage silhouettes and
  actual booster pictograms.
- Campaign/Daily/Shift seeds and solver validation remain independent of UI.
- One global airport replaces five renovation inventories; upgrades cost
  160–230 / 300–450 / 600–850 coins across three stages.
- Shift accumulates unbanked earnings. Cash Out pays 100%; failure pays 60%
  without touching permanent coins. Run seed, round, board, undo history,
  charges and pending banking decisions survive restart.
- Interactive onboarding at stages 1/2/3 and each new mechanic; Replay
  Tutorials starts stage 1 and resets tutorial flags only.
- Contextual HUD, persistent luggage/booster nodes, physical tag conveyor
  dispatch, touch help, reduced motion, EN/UK, responsive safe margins.
- Save schema 3 merges the highest purchased airport stages, refunds surplus
  investment, preserves wallet/completions/boosters and invalidates old seeds.
- All modes, art, sound, progression and saves work offline.

## Run
Install Godot 4.7.2 stable. From the repository:
```powershell
godot --headless --path . --editor --quit
godot --path .
```
432×768 reference, expanding portrait canvas, Compatibility rendering.

## Tests and content
```powershell
godot --headless --path . --script tools/level_baker/bake_campaign.gd
godot --headless --path . --script tests/run_all.gd
godot --headless --path . --script tools/level_baker/stress_generation.gd -- 10000
godot --headless --path . --script tools/level_baker/economy_report.gd
godot --path . -- --qa-flow
godot --path . -- --qa-flow --english
```
The baker explicitly fails if a quality candidate cannot be produced.
The stress tool independently solves every accepted board. Four contiguous
2500-seed runs can pass offset/output arguments and be merged using
`tools/level_baker/merge_stress.gd`; that merger checks sample coverage and
uses all 10000 raw solver timings for percentiles.

QA flow uses an isolated in-memory profile and actual game actions/animations.
It plays stages 1–3 and a hard stage, buys an upgrade, opens Daily, completes
Shift, cashes out, checks Settings and replays onboarding. It captures
`build/qa-uk/` or `build/qa-en/` without overwriting the player's save.

## Art and actual screenshots
```powershell
godot --headless --path . --script tools/asset_generation/generate_assets.gd
godot --headless --path . --editor --quit
godot --path . -- --capture-screens
godot --path . --script tools/asset_generation/render_store_art.gd
godot --path . --script tools/mobile_viewport_audit.gd -- --capture-screens --device-audit --viewport=1080x2400
godot --path . --script tools/mobile_viewport_audit.gd -- --capture-screens --device-audit --viewport=720x1600
```
Store captures use supported game states and isolated progress. There are six
raw captures in `store/screenshots/`; five travel-poster frames in
`store/presentation/` use those exact pixels. Feature PNG is 1024×500.
Raster airport atmosphere was created with built-in imagegen; all interactive
art/icons/worlds are reproducible SVG. See `docs/VISUAL_BIBLE.md` and
`docs/ART_PROVENANCE.md`.

## Puzzle quality
Groups and physical stacks are independent. Seeded partial stack scrambling
adds exposure tradeoffs. Each candidate passes bounded search, outcome-based
choice analysis and six deterministic runs for each simulated player profile:
random, greedy and balanced. The generator rejects unsolved, low-pressure,
nearly-linear, too-forced and insufficiently strategic boards.

Expected winning-path pressure floors are 3 / 4 / 4 / 5 / 5 across worlds.
Early ordinary stages cap at 4; later paths cap at 6. Hard/Rush stages reject
candidates where Greedy wins almost every simulation. Later boards also
require a reasonable Balanced success rate. Runtime generation runs on a
worker thread while the app displays preparation; it never runs per frame.
An exhausted 96-attempt budget widens to 384. Exhaustion remains an explicit
error and never returns a knowingly weak candidate.

See `data/campaign/validation_report.txt`, `stress_report.json`,
`economy_report.json` and `docs/VALIDATION.md` for measured results.
The measured 63.19% candidate rejection exceeds the rough 15–35% guide;
later-world calibration and low-end device generation timing remain open.

## Economy
The former five-world renovation cost was 49350 coins. The global airport
costs 9050. A documented alternating 2/3-star first-clear simulation earns
7375 including the initial wallet, buys 18 of 21 upgrades (86% visual
completion), and averages one upgrade per 4.17 campaign levels. Daily and
Shift fund remaining prestige stages. See `docs/ECONOMY.md`.

## Android
Requires Godot 4.7.2 export templates, JDK 17, SDK API 36, Build Tools 36.0.0
and the Godot Gradle template.
```powershell
$env:GODOT_PATH = 'C:\path\to\Godot_v4.7.2-stable_win64_console.exe'
.\scripts\build_debug.ps1
```
Output: `build/lost-and-sorted-debug.apk`, package
`com.lostandsorted.game`, version 2.1.0/code 3, Android 7.0+/API 24–36.
Build/QA/store/docs/tool artifacts are excluded from the APK. Core resources
have no online dependency. Android safe-area insets are converted from
physical display pixels to the current logical viewport.
Build scripts archive an existing marked Godot-generated src/main/assets tree
under ignored build/android-assets-backup-* before export, so obsolete files
cannot survive exclusions. These recoverable backups are not player saves.

For release set `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`,
`GODOT_ANDROID_KEYSTORE_RELEASE_USER`,
`GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` outside Git and run
`scripts/build_release.ps1` or `scripts/build_release.sh`.
The release AAB requires the publisher's signing credentials.
Optional ads remain disabled unless consent and publisher configuration exist.

## Boundaries
GameState owns rules. Generator/Solver/Simulator/Economy are UI-independent.
Screens/components own presentation. SaveService owns persistence and currency
transactions. See `docs/ARCHITECTURE.md`. Godot is MIT licensed; no new
third-party fonts or online libraries were bundled.

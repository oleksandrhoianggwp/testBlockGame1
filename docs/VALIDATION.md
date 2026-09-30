# Validation — Lost & Sorted 2.1.0 / build 3
Date: 2026-09-30. Engine: Godot 4.7.2 stable, Compatibility renderer.
Baseline: commit 914b9faa185f74a887f48881ad446ad46bd7b229.

## Automated evidence
- Baseline domain suite: 29/29. Expanded suite: 55/55.
- Campaign: 75/75 independently solved and accepted by revision-3 thresholds.
- Full stress: 10000 unique seeds, four contiguous 2500-seed processes.
  0 generation/quality failures; 0 impossible accepted boards.
- Both EN/UK real player-flow QA runs pass. They use actual move/booster
  actions and animations, not directly setting a board to WON.
- Exact desktop-rendered layout captures: 432×768, 1080×2400, 720×1600.
- Android debug export, v2 signature, manifest and clean package checks pass.

Tests cover deterministic/retry seeds, domain mechanics, transfer conservation,
mid-game shuffle safety, solver/non-linear quality, profile simulations,
global migration/refunds/idempotence, JSON numeric round-trip, small perks,
cash-out/failure accounting, duplicate banking protection, Shift board/history/
charge persistence, tutorial replay and EN/UK key parity.
The build pipeline archives marked generated Android assets before export;
APK ZIP contents are checked for stale test/tool/store files, not just a valid
signature. Gradle daemon use is disabled for process completion.

## Difficulty: before and after
Baseline stress (10000): 1.02 attempts/accepted board, approximately 2%
candidate rejection, branching 5.17, forced ratio .05. Baseline 75-board
campaign mean winning-path peak pressure was 3.60, range 3–5.

New stress: 27166 generated candidates for 10000 accepted boards.
17166 rejected candidates, 63.19% rejection, 2.72 attempts/accepted board.
Average branching 4.97, initial selectable 6.335, forced ratio .05,
outcome-based meaningful-choice score .768. Simulated peak pressure 5.831.
New baked campaign mean winning-path peak: 4.747 (baseline 3.60).
Mean per-board failure pressure/moves in the 75 baked boards: 6.104 / 9.834.
Those are unweighted board means, not full-stress aggregate failure metrics.
Independent solver times: p50 39ms, p95 106ms, p99 152ms; maximum 1430 nodes.
Generation mean 601ms under four-process desktop contention. This is NOT a
low-end Android performance benchmark or a directly comparable single-thread
timing claim.

| World | Winning-path peak | Random win | Greedy win | Balanced win | Rejection |
|---|---:|---:|---:|---:|---:|
| Regional | 3.264 | 82.7% | 98.4% | 99.9% | 20.1% |
| International | 4.958 | 37.7% | 86.5% | 99.0% | 51.0% |
| Cargo | 5.126 | 27.9% | 79.6% | 97.9% | 46.8% |
| Midnight | 5.301 | 6.8% | 55.0% | 95.2% | 58.4% |
| Skyport | 5.384 | 1.3% | 31.2% | 91.5% | 83.4% |

All-board Random/Greedy/Balanced wins: 31.4% / 70.2% / 96.7%.
Six deterministic runs/profile/board; total 180000 simulated accepted-board
plays. These are heuristic calibration rates, not human win-rate telemetry.
Hard/Rush filtering additionally rejects excessive Greedy success.
Failure pressure and moves-to-failure are recorded per board in index.json
and level JSON quality; they are not falsely presented as full-stress totals.

Important deviation: rejection is above the requested approximate 15–35%
guide after world 1. Nothing is randomly rejected to manufacture a metric.
Filtering is quality-based; later worlds prioritize pressure and strategic
choices. Human playtesting and low-end generation latency are still required.
Do not describe the rough rejection target as met.

## Economy
Before: 49350 total coins across five inventories. After: 9050 for one
airport. Alternating 2/3-star first-clear model earns 7375 including initial
wallet, purchases 18/21 stages (86%), averages 4.17 clears/upgrade, and leaves
725 coins. Daily/Shift are not included. See economy_report.json and ECONOMY.md.

## Visual/flow QA
Captured first-session Home; stages 1/2/3 tutorials and wins; airport before/
after and upgrade sheet; campaign/hard board; Daily briefing/board; Shift
board/bank/cash-out; Settings; replayed tutorial; conveyor failure.
Both locales: build/qa-uk/ and build/qa-en/.
Six raw store screens: store/screenshots/. Five frames: store/presentation/.
Exact-sized mobile layouts: build/device-1080x2400/, build/device-720x1600/.
Fixed visual issues found by QA: sheet behind buildings, oversized coin
particles, SVG wordmark not rendered, cramped campaign captions, unbounded
result height, and Windows viewport clamping. Screens are inspected after
capture; the success log alone is not accepted as visual evidence.

## Android and release boundary
Debug package: com.lostandsorted.game, version 2.1.0/code 3, min SDK 24,
target SDK 36, ARMv7 + ARM64. Single offline APK at
build/lost-and-sorted-debug.apk. Build tooling: JDK17, SDK36, export and Gradle
templates. Signature/manifest checks are separate from device playback.
Final APK: 167410556 bytes (159.66 MiB), 477 ZIP entries, one signer,
v2 verification PASS. No assets/tools, tests, store, docs or build entries.
SHA-256: F175518BBC85BE42CF5CD634C1E5E41A2E8D4B957C9B8A2EA6C72862AF4CBED4.
The first export encountered a OneDrive Gradle clean lock. Only generated
cache/resource folders were moved to recoverable ignored backup directories.
The final scripted build exits successfully with daemon use disabled.

No connected Android device or SDK emulator was available. Physical FPS,
touch latency, notch/navigation safe-area, haptic feel, update-install and
airplane-mode testing remain unverified. The debug APK is not a signed
Google Play release AAB. Publisher signing/privacy/Play inputs remain external.

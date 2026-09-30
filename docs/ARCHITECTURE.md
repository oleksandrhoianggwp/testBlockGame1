# Architecture
GameState remains authoritative for selection, blockers, destination choice,
matching, lock/key state, deadlines, undo and termination. Presentation never
decides puzzle outcomes. Existing offline services and export workflows remain.

| File/component | Responsibility |
|---|---|
| app/main.gd | routes, threaded preparation, gameplay transactions, tutorial sequencing, rewards, QA capture |
| app/ui_theme.gd | palette, hierarchy, touch dimensions, Android safe margins, common navigation/motion |
| app/screens/ | Home, Campaign, Gameplay, Airport, Shift, Daily, Settings, Result |
| airport_scene.gd / airport_zone_view.gd | connected hub geometry and clickable stage artwork |
| upgrade_sheet.gd | touch-visible before/after preview, price and final-stage benefit |
| tutorial_overlay.gd | one-sentence contextual guidance and target pulse |
| shift_bank_panel.gd | current earnings and Cash Out/Continue decision |
| reward_popup.gd | coin travel presentation |
| luggage_view.gd / tray_view.gd | persistent suitcase silhouettes and conveyor dispatch |
| booster_button.gd / level_node.gd / flight_objective.gd | contextual tools, varied map nodes and goals |
| core/gameplay/game_state.gd | serializable domain and exact undo |
| core/generation/level_generator.gd | seeded templates, geometric overlap, controlled stack scrambling, quality rejection |
| core/solver/level_solver.gd | bounded search, outcome equivalence, solution pressure |
| core/solver/difficulty_simulator.gd | random/greedy/balanced deterministic legal-play profiles |
| core/progression/airport_economy.gd | global prices, progress, perks and capped Shift multiplier |
| services/save_service.gd | schema-3 migration, atomic writes, wallet and bank transactions |
| data/configs/ | campaign and economy values |
| tools/asset_generation/ | source SVG/WAV generation and GPU rendering of store typography |
| tools/level_baker/ | bake, independent stress validation/merge and economy simulation |

Gameplay luggage and boosters persist between moves; tray is drawn in one
Control. Dispatch previews the inserted tag before the domain-resolved tray is
shown. Nodes are updated in place. Generation runs once on a worker thread,
with a preparation view and widened retry budget; it is not a rendering task.

Outcome-based meaningful choice groups actions by destination/tray count,
newly exposed individual paths, key unlock and Priority effect. Equivalent
destination taps without changed exposure are not counted as separate choices.
This is an approximation, complemented by simulated strategy success.

Simulation is seeded by layout/profile/run. It uses GameState without undo
history to avoid allocations that are irrelevant to validation. Search owns
its copied snapshot and avoids a second deep copy. Pure gameplay behavior
does not depend on those optimization flags.

Save schema 3 keeps one airport dictionary. Schema-1 level migration still
maps 150 old levels to 75. Schema-2 airports merge highest stages and refund
surplus value. Content version 3 clears incompatible campaign seeds while
preserving progression. Numeric JSON roundtrips explicitly preserve int/float
fields. Shift stores seed, next round, unbanked earnings, score/high score,
pending result decision, board snapshot, undo history and remaining free perks.
Pending awards and Cash Out are idempotent.

Screenshots/QA use an in-memory profile with persistence disabled. Build output
has .gdignore and is excluded alongside docs/store/tests/tools in Android
presets. Core JSON config and generated levels remain packaged. Release
signing stays outside Git.

# QA and release boundaries
Automated commands and measured results are in README and docs/VALIDATION.md.
The application --qa-flow uses real selections and animations in isolated
profiles, captures every important screen and exits nonzero on a failed flow.

## Desktop flow
Fresh Home → Level 1 pickup/match → Win → Level 2 blocking → Win → Level 3 tray
risk → Win → Airport before/upgrade sheet/purchase/after → Campaign → Hard 8 →
Daily briefing/board → Shift event/round/win/bank → Cash Out → Settings →
Replay Tutorials → Failure presentation.
Run both Ukrainian and English. Inspect build/qa-uk and build/qa-en.

## Automated domain coverage
Matching/overflow ordering, exposure/geometry, Mystery with choices, locks,
Priority deadline, exact undo, extra slot, safe shuffle, seed persistence,
Daily/Shift reproducibility, transfer choices, progression and schema migration.
New coverage: global price/perks, preserved/refunded old purchases, migration
idempotence, economy affordability, bank idempotence, multiplier, failure payout,
numeric JSON roundtrip, active snapshot merge, tutorials/replay, deterministic
player simulations, equivalent outcome rejection, strengthened 75-board quality,
unique EN/UK translations and focused normal HUD.

## Visual checks
- [x] Six real game screenshots and actual-screenshot store frames generated.
- [x] Connected clickable airport instead of a card grid.
- [x] Upgrade sheet contains before/after, cost, benefit and touch controls.
- [x] Boarding HUD hides unconstrained move counts.
- [x] Suitcase/tag branding replaces checklist icons.
- [x] Real Undo/Shuffle/Extra Slot/Reveal pictograms.
- [x] Tutorial overlay, bank choice, completion and full-conveyor failure visible.
- [ ] Final Android hardware review for cutouts/navigation/physical touch feel.

## Device/release checks still requiring hardware or publisher
- [ ] Measure stable 60 FPS on ordinary Android phone; desktop success is not this proof.
- [ ] Install/start on physical device or configured emulator.
- [ ] Airplane-mode lifecycle, app kill/resume and real haptic feel on device.
- [ ] Play internal-track signed AAB using production keystore.
- [ ] Human playtesting calibrates heuristic difficulty and desired rejection range.

# Manual QA checklist

## Gameplay

- [ ] A normal opening shows 4–10 selectable luggage pieces and at least two destinations.
- [ ] Blocked luggage remains colorful and visibly below the pieces covering it.
- [ ] A selected suitcase lifts, travels into the exact tray slot, and does not rebuild the full screen.
- [ ] Three matching tags bounce/dispatch after insertion and before capacity loss.
- [ ] A seven-item unresolved tray explains failure clearly.
- [ ] Retry after failure reproduces item positions, destinations, mechanics, and event.
- [ ] Replay after a completed campaign level may produce a fresh validated board.
- [ ] Reduced motion removes travel/particle movement without changing timing or rules.

## Mechanics and boosters

- [ ] Mystery reveals while multiple board choices remain.
- [ ] One key unlocks every matching lock across different pile paths and uses no tray slot.
- [ ] Priority Flight counts normal luggage moves, succeeds on the deadline match, and explains failure.
- [ ] Transfer Baggage asks PAR/ROM-style choice before moving and resolves the selected tag.
- [ ] Undo restores normal, match, key, Priority, Transfer, and Belt Jam state.
- [ ] Shuffle changes eligible destinations and the resulting board remains solvable.
- [ ] Extra Slot applies once; renovation free Undo and Mystery Reveal each apply once per level.

## Modes and progression

- [ ] Campaign map scrolls vertically through five worlds and exactly 75 stages.
- [ ] Hard stage 8 and Rush stage 15 are visually distinct in each world.
- [ ] Daily is identical on the same date and rewards only once.
- [ ] Airport Shift resumes persisted run/round and reproduces the same event.
- [ ] Priority Flight, Lost Tag, Belt Jam, VIP Baggage, and Heavy Load Shift events are beatable.
- [ ] Shift score/high score survive restart; leaving a failed run ends the active shift safely.
- [ ] Completing a level unlocks the next configured stage and clears only that campaign seed.

## Airport and economy

- [ ] Seven renovation objects have distinct silhouettes and four visible stages.
- [ ] Purchase deducts the displayed cost exactly once and survives restart.
- [ ] Final Baggage, Security, Cafe, and Tower milestones activate their documented small perks.
- [ ] Result screen shows stars, coins, challenge status, and renovation percentage.
- [ ] The full game remains playable with ads disabled and in airplane mode.

## Migration and localization

- [ ] A schema-1 debug save opens without error and maps old level 150 to stage 75.
- [ ] Old Seating/Departures progress maps to Baggage Hall/Control Tower.
- [ ] Corrupt primary save recovers backup; deleting both creates clean defaults.
- [ ] English and Ukrainian contain no mixed player-facing labels or raw translation keys.
- [ ] Language, text size, audio, haptics, and reduced-motion settings survive restart.

## Devices and release

- [ ] Check 360×640, 360×800, 390×844, 412×915, 432×768, 1080×2400, and portrait tablet.
- [ ] Android gesture/navigation insets do not cover tray or bottom controls.
- [ ] Stable 60 FPS on target low/mid-range hardware with a dense Skyport board.
- [ ] Force-close during campaign, Daily, Shift, result, and renovation preserves valid state.
- [ ] APK signature/package/min/target SDK verify; signed AAB installs from Play internal testing.

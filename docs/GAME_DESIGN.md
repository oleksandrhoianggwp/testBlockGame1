# Game design — 2.1
Tap exposed luggage, manage seven conveyor slots, and dispatch triplets of one
destination. Geometry creates physical blockers; destination groups are not
layers. Keys use no slot. Mystery reveals on exposure. Priority uses moves,
not real-time stress. Transfer tags present two choices. Shuffle protects
destinations already in tray, Priority and Transfer counts.

## Journey and calibration
Five configured worlds contain 15 stages each: Regional, International, Cargo,
Midnight and Skyport. Themed map scenery embeds different normal/reward/hard/
milestone/finale nodes. Stages 5,8,10,15 mark those stops. Retry preserves the
saved unresolved seed; clearing removes it for future replay.

Winning-path pressure floors are 3/4/4/5/5, with early ordinary cap 4 and later
cap 6. Quality uses solvability, opening count, branching, forced ratio, outcome
choice score and simulation. Random play should often fail later. Greedy can
complete many ordinary stages but does not guarantee hard boards. Balanced
play considers exposure and Priority. These are heuristic profiles with six
seeded trials, not proof of human difficulty or enjoyment.

A rejected candidate is regenerated deterministically. Runtime uses 96
attempts, then a wider 384 budget. Baked failure is explicit. No unsafe/weak
best-so-far fallback is silently returned. CPU preparation is asynchronous.

## One airport
Home and Airport share the same connected hub. Tap a building for a bottom
sheet showing current/next artwork, cost and benefit. Seven zones have four
visual stages; purchase transforms only that object with construction/confetti,
sound and haptics. The hub carries through all worlds.

Perks: final Baggage one Undo, Security one Reveal, Tower one Priority move,
Cafe +10 first-clear coins, Check-in +5 campaign coins. Entrance/Runway are
visual prestige. Renovation is optional; no progression paywall.

## Shift risk
Seeded rounds preserve five event types: Priority, Lost Tag, Belt Jam, VIP and
Heavy Load. Each appears on a brief airport-board banner and HUD. Rewards enter
unbanked Shift Earnings. Next-round multiplier grows by .25 to a cap of ×3.
After a win, Cash Out banks 100% or Continue takes another round. Failure banks
60% and ends the run. Permanent wallet coins are never deducted. Closing the
app retains the active board and pending bank decision.

## Daily and onboarding
Daily uses date plus content salt. Its preflight board shows completion, best
score, streak and reward. Replay can improve best score but pays no second
daily reward. The streak is tracked locally.

Level 1 explains pickup then automatic matching, Level 2 physical blocking,
Level 3 tray risk. New mechanics receive one contextual sentence and focus
pulse. Completion is saved per tip. Replay clears tips and opens Level 1.
Booster first tap provides touch help without spending; later taps act.

## Feel and access
Readable colored luggage stays visible when blocked. Consistent tags use
destination codes plus shell patterns. Availability pops, pickup lifts and
travels, matches glow/stamp/slide along the conveyor, combos add particles,
rewards animate coins, upgrades transform buildings. Short distinct audio and
light/medium/strong event haptics respect settings. Reduced motion suppresses
translation, scaling, particles and idle vehicle movement.

Settings groups audio, accessibility, language and other links. Every game
sentence is EN/UK localization data. Buttons are at least 44 logical pixels.
Android display insets are mapped to portrait logical coordinates.

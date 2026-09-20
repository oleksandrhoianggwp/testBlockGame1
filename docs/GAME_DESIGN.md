# Game design

## Core loop

The player reads a layered luggage pile, taps one accessible case, watches it enter the tray, and tries to make destination triplets before seven slots fill. A match removes exactly three pieces, scores 100 plus a combo bonus, and exposes the next layer. Levels are short and deterministic; the tension comes from sequencing, not hidden randomness.

## Campaign

Five 30-level worlds form the 150-level campaign: Local Terminal teaches base matching; International Terminal introduces revealed Mystery luggage; Cargo Terminal adds reachable keys and locks; Midnight Hub adds move-limited Priority Flights; Skyport combines established rules. The first three levels are tightly controlled. Level 150 uses all established mechanics and is solver-verified.

Campaign access depends only on completed levels. Renovation and stars never gate play.

## Mechanics and boosters

- Mystery destination is hidden only while covered and reveals as soon as it becomes selectable.
- A key consumes no tray slot and unlocks every item in its lock group.
- Each normal selection decrements Priority moves; keys do not. Dispatching that destination's triplet succeeds at zero, but any other unresolved flight at zero loses.
- Undo restores the complete pre-action domain snapshot.
- Shuffle preserves counts and solvability by remapping whole remaining destination groups.
- Extra Slot expands capacity from seven to eight once per attempt.

Starting inventory is Undo 3, Shuffle 3, Extra Slot 2. Campaign is validated and beatable without them.

## Results, score and economy

A triplet scores 100 with +20 per continuing combo. Priority flights add remaining-move bonus; clear adds 250. Three stars require at most one booster and peak tray pressure of five or less; two allow two boosters; any clear earns one. A normal clear gives 40 coins, 10 per star, 20 extra on first clear and 15 for priority levels.

The player begins with 200 coins. Each world has six renovation objects and three visual stages. Costs are 100, 150 and 220 times the world number. Fully upgrading an object grants a rotating booster. Upgrades are cosmetic.

## Additional modes

Daily Challenge derives its seed from local date, content version salt, and stable hashing. It grants once per local date, tracks best score, and maintains a simple consecutive-day streak up to seven. Device date changes reset rather than corrupt state.

Endless unlocks after campaign level 20. Each cleared round raises the generated difficulty; score carries between rounds and local high score persists. Tray overflow ends the run.

## Onboarding and accessibility

Contextual prompts appear on campaign levels 1, 2, 3, 31, 61 and 91, then persist as completed. Settings can replay them. Destination code, symbol, color and pattern communicate identity together. Large touch targets, portrait safe margins, text scaling, sound/haptic toggles and reduced motion are available.

## Monetization

The core game is complete offline. Optional rewarded ads can continue once with one temporary slot; interstitials are reserved for natural transitions and are never required. The shipped desktop service is a controllable mock. Android production ads remain disabled until publisher IDs, UMP consent and the pinned plugin are configured.


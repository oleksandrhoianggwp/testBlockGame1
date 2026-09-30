# Game design

## Core loop

The player taps exposed luggage in a layered airport pile. The chosen item animates into a seven-slot conveyor tray. Three pieces assigned to the same destination dispatch and leave the tray. Clearing all luggage wins; reaching capacity after match resolution loses.

The board is a spatial decision puzzle, not a sequence of destination layers. Five to eight overlapping pile regions normally expose four to ten pieces from several destinations. A safe triplet may exist, but other exposed tags tempt the player to trade tray capacity for access to deeper luggage.

## Campaign

Campaign structure lives in `data/configs/campaign.json`. It currently defines five worlds with 15 stages each:

1. Regional Terminal: core sorting, overlap depth, first hard stage and Rush milestone.
2. International Terminal: Mystery Baggage appears in varied selectable states.
3. Cargo Hub: keys open luggage across multiple pile paths.
4. Midnight Airport: move-based Priority Flights require planning.
5. Skyport: Transfer Baggage combines the established mechanics.

Stage 8 is a hard level; stage 15 is a Rush/milestone board. A template controls groups, destination range, pile count, mechanics, and difficulty. The first-open seed is saved until clear, so Retry is fair and reproducible.

## Mechanics

- Mystery Baggage: its tag is hidden while covered and reveals when selectable. Because multiple destinations remain exposed, the reveal adds information to a real choice.
- Locks and Keys: a key occupies one selectable path, unlocks a group spanning other pile regions, and never enters the tray.
- Priority Flight: a non-opening destination must dispatch within a move budget. Keys do not consume the budget.
- Transfer Baggage: shows two destination tags. The player chooses which flight receives it before the item enters the tray.
- Belt Jam: an Airport Shift event temporarily blocks one pile region for a small number of normal moves.
- VIP Baggage: dispatching the marked destination without a booster grants a bonus.

Campaign pressure uses moves, never real-time timers.

## Airport Shift

Airport Shift replaces the old endless mode. A persisted run seed and round number reproduce both the board and event. Difficulty increases across rounds. Events are applied before solver validation:

- Priority Flight
- Lost Tag
- Belt Jam
- VIP Baggage
- Heavy Load

No event may ship an impossible board. Score and high score remain local.

## Airport renovation and economy

Coins come from first clears, stars, Daily, Shift, and challenge bonuses. They fund seven visible airport zones with four visual states: Entrance, Check-in, Baggage Hall, Security, Cafe, Control Tower, and Runway.

Final zone stages can provide small perks: a free Undo charge, a Mystery reveal, extra Priority movement, or a first-clear coin bonus. These perks reduce friction without replacing puzzle decisions.

## Stars and results

Three stars reward low booster use and controlled tray pressure. Every win shows stars, coins, challenge status, and airport renovation progress. Failure identifies tray overflow or a missed Priority Flight. Retry always reuses the same unresolved board.

## Accessibility and offline play

Destination identity combines code, color, tag shape, and luggage treatment. Settings include EN/UK language, text scaling, sound, music, haptics, and reduced motion. All gameplay and persistence work in airplane mode.

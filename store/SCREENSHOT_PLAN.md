# Store presentation
Raw game captures: store/screenshots/home.png, campaign.png, gameplay.png,
airport.png, daily.png, shift.png. Capture with --capture-screens using an
isolated supported state. No player save is modified.

Five posters in store/presentation use the actual screenshot pixels, a navy
travel-poster frame and minimal English headline:
1. Gameplay: SORT YOUR NEXT FLIGHT.
2. Airport: BUILD YOUR AIRPORT.
3. Campaign: 75 STAGES. FIVE WORLDS.
4. Shift: BANK IT. OR RISK IT.
5. Daily: A NEW FLIGHT EVERY DAY.

Feature art is 1024×500: original terminal-window/conveyor/luggage composition,
LOST & SORTED wordmark, SORT. FLY. BUILD. tagline. Native Godot text is rendered
into final PNGs because SVG text support is not assumed.

Keep raw screenshots separately from promotional framing. In-game EN/UK flows
are captured under build/qa-en and build/qa-uk. Resolution audits are under
build/device-1080x2400 and build/device-720x1600. Device cutout and OS-bar review
still requires an Android device.


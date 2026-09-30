# Release checklist — 2.1.0

## Validated locally
- [x] Version 2.1.0/code 3 in both presets and configuration.
- [x] 55 automated tests; 75 campaign boards; 10000-board stress without failure.
- [x] EN/UK real-flow QA and original adaptive/monochrome suitcase icons.
- [x] Real screenshots and 1024×500 feature PNG.
- [x] Debug APK 2.1.0/code 3, v2 signature and clean ZIP contents verified.
- [x] Save schema1/2 migration, numeric JSON round-trip and isolated QA profiles.
- [x] Ads remain disabled without publisher setup; local analytics are debug-only.

## Required before Play production
- [ ] Publisher-owned package identity and public privacy contact/URL.
- [ ] Backed-up release keystore outside Git.
- [ ] Signed release AAB, manifest check and Play internal-track upload.
- [ ] Data Safety, content rating and store copy reviewed by publisher.
- [ ] Physical install/update, FPS, memory, touch, notch and haptics QA.
- [ ] Airplane-mode play and real interrupted-Shift/force-close save recovery.
- [ ] Human difficulty/economy playtesting; later generation latency calibration.
- [ ] Production AdMob/UMP setup and test-device validation only if enabling ads.


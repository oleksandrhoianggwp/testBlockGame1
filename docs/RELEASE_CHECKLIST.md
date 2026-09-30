# Release checklist

- [ ] Version name/code updated in config and both export presets.
- [ ] `75/75 levels validated`; 10,000-board stress has zero impossible boards and acceptable p95 solve time.
- [ ] Import, parser, unit/integration and headless smoke tests pass in CI.
- [ ] Debug menu and debug local analytics absent from release behavior.
- [ ] Publisher-owned package ID replaces `com.lostandsorted.game`.
- [ ] Production AdMob app/unit IDs supplied outside Git; v7.0 license/notices reviewed.
- [ ] UMP consent and privacy-options reopening tested in applicable regions.
- [ ] Release keystore backed up and signing variables configured outside Git.
- [ ] Target API 36 verified from built AAB manifest and Play Console.
- [ ] Launcher, adaptive foreground/background and monochrome icons verified.
- [ ] Hosted privacy-policy URL uses real publisher contact.
- [ ] Store listing, Data Safety answers and content rating reviewed by publisher.
- [ ] Release AAB built and uploaded to Play internal testing.
- [ ] Install/update from Play internal track on at least two aspect ratios.
- [ ] Airplane-mode, schema-1 save migration, force-close and corrupted-save tests pass.
- [ ] Ads tested only with test devices before switching to production units.
- [ ] Crash/log check and final smoke test complete.


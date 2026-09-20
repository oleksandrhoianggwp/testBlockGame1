# Decisions

1. Compatibility renderer is used for broad low/mid-range Android support.
2. The reference canvas is 432×768 with Containers and normalized board positions; Godot stretch handles common portrait ratios.
3. Minimum SDK 24 is the development baseline; target SDK is 36 as required by the product brief. Reconfirm the final minimum against the installed AdMob v7.0 artifact before publication.
4. Campaign boards are constructive triplet layers with an independent solver pass. This favors reliable short sessions over opaque random difficulty.
5. Keys do not consume Priority moves because they do not enter the tray.
6. Campaign JSON is immutable at content version 1; changing generation alone cannot silently alter shipped boards.
7. AdMob binaries are not vendored without publisher setup. The project pins optional `godot-sdk-integrations/godot-admob` v7.0, which states Godot 4.7 support; desktop/release-without-ads behavior remains complete.
8. No external font is bundled. Godot's platform font fallback supplies Latin and Cyrillic, avoiding an unnecessary third-party font license.
9. Local analytics are debug-only JSONL with no identifiers and no network transport.
10. Final publisher identity, production package ID, AdMob IDs, privacy contact and signing credentials are external release inputs.


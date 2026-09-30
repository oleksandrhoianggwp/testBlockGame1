# Decisions — content revision 3
1. Preserve GameState/Generator/Solver and the existing screen/service split.
2. Compatibility rendering, 432×768 expanding portrait canvas and small SVGs
   support broad hardware; exact mobile layout render is not device FPS proof.
3. One global airport replaces per-world inventories. Migration takes highest
   stage and refunds excess old investment; no wallet/completion/booster loss.
4. Costs are explicit per-zone stages, never multiplied by campaign world.
5. Shift unbanked earnings are transactional: 100% voluntary cash-out, 60%
   failure, no permanent wallet loss. Board/history/charges survive restart.
6. Exposure scrambling and outcome equivalence make choices strategic.
   Solver proof, pressure floors and deterministic profile simulations reject
   candidates on quality. Exhaustion fails explicitly and widens at runtime.
7. The 63.19% rejection rate exceeds the approximate guide; preserve measured
   results and mark calibration needs rather than weakening or hiding evidence.
8. Native font rendering is used for final PNG branding because Godot SVG
   import does not render the SVG wordmark text.
9. Original imagegen atmosphere/key art complements interactive reproducible
   vector assets. No third-party fonts/audio are downloaded.
10. Ads stay optional and disabled without publisher setup/consent. Debug local
    analytics stay local. Signing credentials and publisher contact stay out
    of Git. Debug packaging is not Play production certification.


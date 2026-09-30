# Original art provenance — polish revision 3

Visual rules were established in VISUAL_BIBLE.md before asset production.
No existing game's UI, character, icon or illustration was copied.

## Raster illustrations
Created with the built-in imagegen tool, not the imagegen CLI. Files:
- assets/art/airport_atmosphere.png: original portrait airport atmosphere.
- assets/art/feature_background.png: original wide conveyor/terminal illustration.

Airport prompt:
"Use case: stylized-concept. Create ORIGINAL premium stylized casual 2.5D airport
art for an offline mobile luggage puzzle. Portrait airport landscape with warm
matte illustrated architecture, deep navy #17223D, cream #FFF8EB, sky #DDEFF4,
mint #75CDB2, coral #F06F6C, yellow #F7C75A and blue #5B91E8. Cream terminal,
blue glass, control tower, runway, aircraft and service vehicle; warm sunlight,
soft shadows, clean charming geometry. Upper half horizon and sky; lower half
quiet airport apron suitable behind interactive buildings. No text, UI, logo,
watermark, photorealism or existing game imitation."

Feature prompt:
"Create an ORIGINAL premium stylized casual 2.5D airport luggage puzzle game
promotional background, using the original airport illustration only as a
consistent style reference. Wide composition intended for 1024×500. Foreground
lower-right: five distinct physical luggage silhouettes: coral hard-shell,
mint cabin roller, golden duffel, blue backpack, purple instrument case, cream
baggage tags with geometric lines but no letters. Navy/mint sorting conveyor.
Middle: baggage infrastructure and warm cream terminal interior with enormous
blue-glass windows. Background right: coral-tail aircraft, runway and tower.
Warm afternoon light, soft contact shadows, highlight edges. Upper-left 55%
clean cream/sky negative space for later wordmark. No text, letters, UI, logo,
watermark, checkmark or grid of interface cards."

The second request referenced the first original illustration. Native Godot
rendering adds the real wordmark/tagline to the final 1024×500 feature PNG.
Neither raster asset is used to fake interactive controls.

## Reproducible assets
tools/asset_generation/polish_assets.gd creates 28 zone-stage SVGs, six real
luggage silhouettes, five themed journey illustrations, five quiet puzzle
backgrounds, the suitcase/tag/aircraft brand and adaptive/monochrome icons,
and original booster/navigation pictograms.

tools/asset_generation/generate_assets.gd creates original offline synthesized
WAV effects and ambient music. No externally sourced sound library is used.

tools/asset_generation/render_store_art.gd renders logo.png, splash.png,
feature_graphic.png and five posters from actual game screenshot pixels.
SVG text is retained for external vector editors, while final PNG wordmarks
use Godot's native font rendering. No newly downloaded font is bundled.

## Capture provenance
Raw captures are in store/screenshots/. QA profiles are isolated in memory;
capture code does not overwrite a real player save. Presentation frames only
add headlines/margins, never invented gameplay. Mobile aspect-ratio audits
render the actual main scene in an exact-sized SubViewport; they are desktop
layout evidence, not evidence of physical-device performance.

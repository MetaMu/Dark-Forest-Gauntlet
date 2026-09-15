# Gnome sprite bases — v1

20 transparent RGBA PNG A-pose frames derived from the five supplied modeling sheets using built-in ImageGen. Five horizontal strips are also included. Originals remain untouched.

## Export contract

- Individual frames: 512 × 512 pixels; straight alpha, sRGB PNG.
- Character silhouette height: 416 pixels, proportionally scaled without stretching.
- Hat top: y=48. Foot baseline: y=464. Shared pivot: (256,464), normalized (0.5,0.90625).
- Strips: 2048 × 512, four 512-pixel cells, no spacing.
- View order: front, side_right, back, three_quarter_right.
- Names: `gnome_{character}_apose_{view}_000.png`; strips: `gnome_{character}_apose_sheet.png`.
- Character IDs: `universal`, `ember_hollow`, `ironbark`, `spore_grove`, `light_realm`.

These are animation base poses, not idle/walk/attack cycles or separated skeletal layers. Preserve the canvas and pivot when adding numbered motion frames. Costume asymmetry means left views should be authored deliberately rather than blindly mirrored.

## Godot use

Import PNGs with lossless compression and alpha border fixing enabled. Use linear filtering for the illustrated edges. For a Sprite2D using a strip, set hframes=4 and vframes=1. With centered=true, offset=(0,-208) places the shared foot pivot at the node origin. Use an equivalent foot offset for Sprite3D billboards. Select each view independently; cycling these four views is not a walking animation.

The existing 3D player remains unchanged. These files are ready for texture import and animation authoring; runtime billboard integration has not been performed or tested.

## Provenance and validation

`prompts.json` records the exact shared built-in prompt and original reference filenames. `sources/` retains generated intermediates and is excluded from Godot imports. The generator returned RGB checkerboards, so the exporter removes exterior neutral pixels bounded by the character outlines, retains the four character silhouettes, and rescales proportionally. No source modeling sheet was overwritten. No additional third-party license is asserted; these derivatives inherit the project's source-art rights requirements.

`manifest.json` records per-frame hashes, source bounds, dimensions and alpha counts. All 20 outputs passed RGBA, size, silhouette count and transparent margin checks; the combined `preview.png` was visually inspected on a dark background. Shared proportions are visually matched to the sheets, not a shared skeletal rig.

Rebuild using `node tools/export-gnome-sprites.cjs` from the project root. The script overwrites only this version's derived exports. Set SHARP_MODULE to a local installed Sharp module path if the bundled runtime is unavailable.

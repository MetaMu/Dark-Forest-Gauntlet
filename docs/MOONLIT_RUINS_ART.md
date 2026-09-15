# Moonlit Ruins art pass

This is a visual replacement for the forest playtest. Combat rules, powers, enemy stats, movement, navigation and encounter progression retain their previous behavior.

## Art direction and scope

Moonlit blue-green woodland, warm brass lanterns, worn masonry and mossy paving. Blender-authored crooked trees, ruin walls, an exit arch and portcullis, fern clusters, rubble, ritual rings, bark creatures, a recurve bow and two realm staffs. Textured Quaternius equipment replaces the flat axe and adds a sword, shield, camp supplies and treasure chest.

The five supplied gnome designs remain the source of the character sprites. They still use the existing stepped cut-paper pose rig; this pass does not create fully rigged 3D gnomes or new hand-drawn animation frames.

## Free sources

- Quaternius Fantasy Props MegaKit **Standard**: https://opengameart.org/content/fantasy-props-megakit — CC0 1.0. Fifteen selected props converted from glTF to embedded GLB in Blender. The source archive's missing relative texture paths are repaired in staging copies; original files are preserved.
- Poly Haven Forest Leaves 02: https://polyhaven.com/a/forest_leaves_02
- Poly Haven Cobblestone Floor 04: https://polyhaven.com/a/cobblestone_floor_04
- Poly Haven Bark Brown 02: https://polyhaven.com/a/bark_brown_02
- Poly Haven Rock Boulder Dry: https://polyhaven.com/a/rock_boulder_dry
- All four Poly Haven materials: CC0 1.0, https://polyhaven.com/license. Three maps per material at 1024 resolution: color, OpenGL normal, roughness.

These are independently licensed fantasy resources suitable for a Gauntlet-inspired game, not extracted proprietary Gauntlet game files. No paid assets or generation services were used.

## Editable sources and reproducibility

- `tools/Import-ArtUpgrade.ps1`: imports approved sources, verifies provider MD5 and size, records SHA-256 and licensing.
- `tools/build_forest_art.py`: Blender 5.2 geometry and conversion recipe; leaves sources intact.
- `artifacts/art-upgrade/blender/Moonlit_Ruins_Library.blend`: editable, spaced library of custom modules.
- `assets/environment/moonlit-ruins/receipt.json`: output file hashes and triangle counts.
- `assets/vendor/quaternius-fantasy/`: selected self-contained GLBs, source archive receipt and original license.
- `assets/vendor/polyhaven-forest/`: original downloaded maps and source receipts.
- `tools/verify-art-upgrade.cjs`: validates exported GLB headers, triangles, embedded dependencies, and every listed SHA-256.

Target: one mesh per exported module with material surfaces, fewer than 60,000 triangles per asset, meters, Godot Y-up, embedded GLB textures capped at 1024×1024. Quaternius texture buffers are resized inside Blender; original downloaded files remain intact. Decorative geometry has no gameplay collision; the existing room collision bodies still define the routes.

## Review

Run `Play.cmd` from the project. Enter starts the encounter. Existing keyboard controls: WASD, Space attack, Shift power, E revive, Esc pause. Walk north to inspect the arch and corrupted sanctum.

`tests/art_capture.gd` captures lobby, four-character entry, ruin walk, sanctum, equipment detail and 960×540 readability. Check `artifacts/art-upgrade/` for the actual game captures and test logs. Static integrity checks and automated gameplay regression checks do not constitute artistic approval; visual feedback is still needed before resuming gameplay development.

Verified for this pass: 30 embedded GLBs and 12 texture maps; 83 existing regression checks passed; six GPU captures inspected on the OpenGL compatibility renderer. The packaged runtime started and exited without engine errors. Every ZIP payload file was checked against its SHA-256 manifest. The portable download is `builds/Dark-Forest-Gauntlet-Moonlit-Ruins.zip`; rebuild it with `tools/Package-MoonlitRuins.ps1` after refreshing the captures.

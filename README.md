# Dark Forest Gauntlet

A playable local co-op forest encounter in Godot 4.7.2: choose a gnome, destroy two spawning Root Hearts and the remaining Rootlings, collect the Golden Pear, then bring every survivor through the Root Gate.

## Play

**3D character overhaul (October 1):** the four playable realm gnomes now use 52-bone 3D rigs with stepped idle, walk, attack, cast, hit, and downed animations. Universal is included in **Play-Battle-Rigs.cmd**. The original sprite sheets remain available. All four Atlas enemy types now use animated models, and the corrected rear-hinged chest is installed. The tested unpacked Windows build is in **builds/3D-Overhaul-Playtest/**. ZIP creation is pending additional free disk space. These are locally tailored derivatives of the shared KnowME body and rig, not newly generated Atlas player meshes.


**Latest: Maria's fifty-pose victory animation is in the game.** Use **builds/Dark-Forest-Gauntlet-Dynamic-Maria.zip**. Escape level two to see the new articulated stop-motion celebration on the parchment scroll. Includes both levels, keyboard co-op, and the repaired Studio magic effects. [Animation notes](docs/MARIA_DYNAMIC_CELEBRATION.md).

**Game Studio magic repair:** corrected projectile sparks, faceted shard wakes and Spore crystals are included. **Watch-Powers.cmd** demonstrates the four powers. [Changes, credits and renderer evidence](docs/STUDIO_VFX_UPDATE.md).

**Pear travel and Maria's victory celebration:** eating level one's Golden Pear automatically begins level two with your chosen party and active gnomes. Escape level two to reveal Maria's looping victory scroll. The Studio build also includes the separately requested **Maria-3D-Jump-50-Frame.gif** as a standalone asset.

**Level two is playable:** open **Play-Level-Two.cmd**, use the lobby's level selector, or eat level one's Golden Pear. The **Bellcap Cistern** adds a new flooded floor plan, three anchors, stronger melee enemies and Mortarcaps that drop marked spore bombs. [Level guide and floor plan](docs/LEVEL_TWO.md).

**Magic effects:** Tower Defense-inspired magic cores, branching arcs, golden shafts and timed lights accompany all four realm powers and are included in the level-two bundle. See [magic and lighting notes](docs/MAGIC_SEQUENCE.md).

**New: two people on one keyboard, with two gnomes each.** Open **Play-Keyboard-Coop.cmd**, choose your pairs and press Enter. The portable build is **builds/Dark-Forest-Gauntlet-Keyboard-Coop.zip**. P1 uses WASD/F/G/Q/E; P2 uses arrows/J/K/L/U for movement, attack, power, switching and revival. Remap keys under **Esc → Keyboard Controls**. See [shared-keyboard instructions](docs/KEYBOARD_COOP.md).

Double-click **Play.cmd** for the normal solo/controller lobby. The latest **Studio-VFX** ZIP includes both modes and **Watch-Powers.cmd**, which shows all four characters casting automatically. In the project folder the showcase launcher is **Play-Power-Showcase.cmd**. The bundle includes a Godot runtime and packed game; no editor installation is required. Windows x64 and OpenGL 3.3 graphics are required. Previous playtest ZIPs remain available.

The original static Universal sprite inspection remains available through **Play-Gnome-Trial.cmd**. It is separate from the main forest encounter.

| Action | Keyboard | Controller |
| --- | --- | --- |
| Move | WASD | Left stick / D-pad |
| Choose class in lobby | 1–4 / Q / click | LB / RB |
| Join | P1 automatic | Start |
| Begin | Enter | Y |
| Attack | Hold Space | Hold X |
| Realm power | Press Shift | Press B |
| Revive nearby ally | Hold E for 2 seconds | Hold A for 2 seconds |
| Pause | Esc | Start during encounter |
| Restart after win/loss | R / menu | Back / menu |
| Fullscreen | F11 / menu | Menu |

One keyboard player and up to three controllers. Join and select classes before combat. Disconnected controllers retain their slots and stop moving. Actual controller and reconnect behavior still needs hands-on testing.

## This playtest

Illustrated gnomes animate as stepped cut-paper puppets over a 3D forest, with visible weapon actions and a full-size sideways fall. Ember has a sweep and dash burst; Ironbark has bolts and a piercing volley; Spore has slowing clouds and a root snare; Light has radiant bolts, small healing pulses, and Sanctuary to heal or revive nearby allies. Powers have cooldowns shown in the HUD. Manual revival remains available to every class.

The Moonlit Ruins art pass adds Blender-built textured ruins, an archway, crooked trees, ferns, bark creatures and 3D weapons. Quaternius CC0 fantasy props provide the axe, sword, shield, lanterns, treasure and camp supplies. Four Poly Haven CC0 materials replace the flat ground and bark/stone surfaces. Kenney impact sounds, synthesized ambience and the existing stepped gnome animation remain. Supplied source art remains untouched. See [art sources and Blender workflow](docs/MOONLIT_RUINS_ART.md).

## Verification and limits

The new power-effects pass adds Ember flames and afterimages, Ironbark arrow trails, target-attached Spore roots and a golden Light Sanctuary with healing halos. Free CC0 textures from Kenney and RPicster are included with licenses and hash receipts. See [power-effects notes and downloads](docs/POWER_FX_V3.md). Captures and a looping motion preview are in `artifacts/power-fx-v3/`.

Run **tools/Test.ps1**: 34 baseline, 25 realm, 24 power/animation, 20 VFX/lighting, 30 shared-keyboard, 23 level-two, 15 campaign/celebration and 12 Studio VFX checks (183 total). Run **node tools/verify-art-upgrade.cjs** for GLB and texture integrity checks. Studio renderer captures and packaged-runtime tests are in `artifacts/studio-vfx/`. Level-two captures and its successful input-driven co-op playthrough log are in `artifacts/level-two/`. Maria's new campaign test results are in `artifacts/maria-dynamic-50/`. Four automated movement-driven solo playthroughs reached victory in the earlier level-one pass.

This is one integrated playtest encounter. Physical controller/co-op testing, human balance, broader performance checks, richer hand-drawn motion and a conventional release export remain. No bosses, additional playable realms, online multiplayer, procedural generation or saved progression are included.

See [forest playtest notes](docs/FOREST_PLAYTEST.md) for attack values, controls, asset provenance and reproducible checks. Vendor licenses and hash receipts are in `assets/vendor/`; screenshots and motion preview are in `artifacts/polish/`.

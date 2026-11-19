# Dark Forest Gauntlet

A playable local co-op forest encounter in Godot 4.7.2: choose a gnome, destroy two spawning Root Hearts and the remaining Rootlings, collect the Golden Pear, then bring every survivor through the Root Gate.

## Play

**Latest � November 18, 2026: synchronized Mixamo casting.** [Download the Windows game](https://github.com/MetaMu/Dark-Forest-Gauntlet/releases/tag/cast-sync-2026-11-18). Extract the entire ZIP and open **Play.cmd** or **Play-Keyboard-Coop.cmd**. Hand energy builds before all four powers release at the animation's **1.2-second forward thrust**. Damage, healing, projectiles and release lights share one clock. Hits cancel unreleased magic with a short retry cooldown; movement remains available. Includes the new walk/run/cast rigs, upgraded power art and Gnomish UI, both levels, and Maria's victory celebration. Faces and cloth are unchanged. Local package: **builds/Dark-Forest-Gauntlet-Cast-Sync-Windows.zip**.

**3D character overhaul (October 1):** the four playable realm gnomes now use 52-bone 3D rigs with stepped idle, walk, attack, cast, hit, and downed animations. Universal is included in **Play-Battle-Rigs.cmd**. The original sprite sheets remain available. All four Atlas enemy types now use animated models, and the corrected rear-hinged chest is installed. The verified Windows ZIP is **builds/Dark-Forest-Gauntlet-3D-Overhaul.zip**; extract it and run **Play.cmd**. The unpacked build remains in **builds/3D-Overhaul-Playtest/**. These are locally tailored derivatives of the shared KnowME body and rig, not newly generated Atlas player meshes.


**Maria's fifty-pose victory animation is in the game.** Use **builds/Dark-Forest-Gauntlet-Dynamic-Maria.zip**. Escape level two to see the new articulated stop-motion celebration on the parchment scroll. Includes both levels, keyboard co-op, and the repaired Studio magic effects. [Animation notes](docs/MARIA_DYNAMIC_CELEBRATION.md).

**Game Studio magic repair:** corrected projectile sparks, faceted shard wakes and Spore crystals are included. **Watch-Powers.cmd** demonstrates the four powers. [Changes, credits and renderer evidence](docs/STUDIO_VFX_UPDATE.md).

**Pear travel and Maria's victory celebration:** eating level one's Golden Pear automatically begins level two with your chosen party and active gnomes. Escape level two to reveal Maria's looping victory scroll. The Studio build also includes the separately requested **Maria-3D-Jump-50-Frame.gif** as a standalone asset.

**Level two is playable:** open **Play-Level-Two.cmd**, use the lobby's level selector, or eat level one's Golden Pear. The **Bellcap Cistern** adds a new flooded floor plan, three anchors, stronger melee enemies and Mortarcaps that drop marked spore bombs. [Level guide and floor plan](docs/LEVEL_TWO.md).

**Magic effects:** Tower Defense-inspired magic cores, branching arcs, golden shafts and timed lights accompany all four realm powers and are included in the level-two bundle. See [magic and lighting notes](docs/MAGIC_SEQUENCE.md).

**New: two people on one keyboard, with two gnomes each.** Open **Play-Keyboard-Coop.cmd**, choose your pairs and press Enter. The portable build is **builds/Dark-Forest-Gauntlet-Keyboard-Coop.zip**. P1 uses WASD/F/G/Q/E; P2 uses arrows/J/K/L/U for movement, attack, power, switching and revival. Remap keys under **Esc → Keyboard Controls**. See [shared-keyboard instructions](docs/KEYBOARD_COOP.md).

Double-click **Play.cmd** for the normal solo/controller lobby. The latest **Cast-Sync** ZIP includes both modes and **Watch-Powers.cmd**, which shows all four characters casting automatically. In the project folder the showcase launcher is **Play-Power-Showcase.cmd**. The bundle includes a Godot runtime and packed game; no editor installation is required. Windows x64 and OpenGL 3.3 graphics are required. Previous playtest ZIPs remain available.

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

## Ember effect upgrade — November 14, 2026

Ember now leaves three frozen snapshots of its current 3D pose and a distance-spaced flame wake. Landing triggers an animated flame burst, ground shockwave, smoke and embers using the existing verified Kenney and Raffaele Picca CC0 textures in `assets/vendor/power-fx`. Damage, dash timing, cooldowns and locomotion remain unchanged. Launch the current source game with `Play.cmd`; existing packaged ZIP builds are not rebuilt by this change.

Actual-renderer preview: `artifacts/ember-upgrade/ember-motion.gif`. Reproduce frames with `tools/godot/Godot_v4.7.2-stable_win64_console.exe --path . --script tests/ember_capture.gd --fixed-fps 60`, then run `node tools/make-ember-preview.cjs`. The capture stages enemies with extra health so all visual phases remain visible. The new eight-check Ember regression is included in `tools/Test.ps1`; the existing 257 checks and all eight new checks passed during implementation. Skin snapshots are visual-only and skipped in headless mode because they require an actual renderer.

## Ironbark effect upgrade — November 14, 2026

Piercing Volley now sends three tapered green streaks with pointed ivory tips, tumbling folded leaves and wood splinter bursts at confirmed enemy or wall impacts. Each hit burst uses the existing CC0 Raffaele Picca flash texture with original leaf and splinter geometry. Ironbark's basic shots share this visual language; Light's projectile effects remain separate. Projectile speed, spread, damage, cooldowns and piercing limits are unchanged.

Actual game preview: `artifacts/ironbark-upgrade/ironbark-motion.gif`. Reproduce with `tools/godot/Godot_v4.7.2-stable_win64_console.exe --path . --script tests/ironbark_capture.gd --fixed-fps 60`, then `node tools/make-ironbark-preview.cjs`. Review targets have extra health. Ten additional checks cover distinct trajectories, bounded leaves, three confirmed piercing impacts, damage and cleanup; they run through `tools/Test.ps1`. Launch `Play.cmd` for the updated source game. Existing packaged ZIP builds have not been rebuilt.

## Remaining power effects — November 14, 2026

Spore Grove now grows five curling roots around each affected target, with violet veins and bounded drifting spores. Growth and retraction follow the root status; lingering slow particles end with the slow status. Light Realm now uses soft textured shafts, a delicate golden ground pattern, arcing healing pulses and personal halos on eligible allies. The effects use the existing CC0 texture set and original code-generated geometry. Healing, revival, damage, cooldowns and locomotion are unchanged.

Actual gameplay previews are `artifacts/spore-upgrade/spore-motion.gif` and `artifacts/light-upgrade/light-motion.gif`. Reproduce with `tools/godot/Godot_v4.7.2-stable_win64_console.exe --path . --script tests/remaining_power_capture.gd --fixed-fps 60`, then `node tools/make-remaining-power-previews.cjs`. The preview stages targets with extra health and suppresses their movement/attacks while allowing status timers to run. Light's preview includes a wounded ally and a real revival.

`tests/remaining_power_regression.gd` adds 17 checks for root growth, attached effects, cleanup, healing range and revival. `tests/all_power_smoke.gd` exercises three repeated casts by all four players, checks the six-light budget, verifies cleanup and saves `artifacts/power-fx-final/all-four.png`. Both are integrated into `tools/Test.ps1`. The source-game launcher remains `Play.cmd`; packaged ZIP builds are unchanged.

## Gnomish interface — November 14, 2026

Character selection, pause, key bindings, defeat and victory share a transparent-edged illustrated parchment scroll, moss-green beveled buttons and an original diamond seal. Gnomish Elder is an original TrueType display font with angular Latin capitals, numbers and common punctuation; lowercase maps to its display capitals. Body text uses a local serif font through Godot SystemFont (Georgia / Palatino / system serif), so no proprietary system-font files are bundled. Floating names and damage numbers use the same readable serif treatment. Combat HUD panels are smaller and translucent, and redundant HUD information is hidden while selecting characters or viewing menus.

The 1280×720 interface scales as a unit for smaller windows. Keyboard controls replace the pause scroll and return to it when closed. The animated Maria victory remains intact. Sixteen UI regression checks cover font loading, true PNG alpha, class selection, menu navigation, game state and 960×540 bounds.

Assets: `assets/fonts/GnomishElder-Regular.ttf`, `assets/ui/gnomish/parchment-scroll.png`, and `assets/ui/gnomish/elder-seal.svg`. The parchment was generated with the built-in image-generation tool; the exact prompt and asset hashes are in `assets/ui/gnomish/source.json`. Font source is `tools/build_gnomish_font.py` (dependencies in `tools/font-requirements.txt`; install into the ignored `tools/font-deps` folder). Body-font appearance may vary on operating systems without the preferred serif fonts.

Reproduce the nine screen captures with `tools/godot/Godot_v4.7.2-stable_win64_console.exe --path . --script tests/ui_capture.gd --fixed-fps 60`; assemble the review with `node tools/make-ui-review.cjs`. Preview: `artifacts/gnomish-ui/Gnomish-Menus-Preview.png`. The menu regression is part of `tools/Test.ps1`. Play the updated source through `Play.cmd`; older packaged ZIP builds are not rebuilt by this change.

### Illustrated gameplay HUD
Player cards now use transparent woodland PNG frames with live colored health fills, numerical health, realm emblems, and power recharge indicators. The top HUD uses parchment quest plaques; enemy meters use cropped ornamental frames instead of block-character text. Cards stay compact for solo play and fit four players at 1280x720 and 960x540. Artwork prompts and hashes: `assets/ui/gnomish/hud-source.json`. Reproduce actual-game screenshots with `tests/hud_capture.gd`. Interface regression coverage is now 24 checks.

### Mixamo character movement — November 18, 2026

The five existing playable/showcase skins now include imported Mixamo **Walking / Walking With A Swagger**, **Running With Intention**, and **Standing 2H Magic Attack 01**. Open **Play-Battle-Rigs.cmd** to cycle idle, walk, run, attack, the full two-handed cast, hit, and down/revive. The regular game selects walk/run by movement speed and advances stride with distance; movement and casting now sample smoothly rather than at 12 fps.

The two-handed spell moves equipment to a back socket, freeing both hands. Movement during casting uses locomotion on the hips and legs. Melee damage timing is unchanged. Powers now use a 1.2-second interruptible wind-up, with the full cast recovering through 2.7 seconds. Equipment uses a fitted palm frame and finger curls; the axe handle has an asset-specific correction.

Editable Blender files and the 15-second review are in `artifacts/mixamo-locomotion/`; original GLBs are preserved under `reference/production/player-locomotion-originals/`. Rebuild with Blender 5.2 using `tools/retarget_mixamo_locomotion.py`. Its three motion-source paths point to the existing local libraries; source hashes and the fitting measurements are recorded in `assets/characters/gnomes/rigged/mixamo-motion-receipt.json`. No new model generation was used. The original Giddy source was not found; this uses the separately documented 24 fps Swagger export and leaves Giddy's approved run untouched.

Scope: shared 52-bone body/finger skins, retargeted movement, grounded standing cast, transitions and runtime equipment. Existing facial geometry, hats and clothing remain as supplied; this does not add facial speech, blinking, cloth simulation, or a new two-handed bow draw. Palm grip corrections live in the Godot rig; the Blender actions contain the underlying motion. Fast gameplay travel produces correspondingly fast short-legged strides, and cadence matching is an estimate rather than an exact contact solver. Power particles and gameplay effects now activate together at the 1.2-second hand-release marker.

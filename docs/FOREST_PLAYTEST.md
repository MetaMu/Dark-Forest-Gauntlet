# Forest encounter playtest

**Superseded by combat v2:** see [current combat notes](COMBAT_V2.md) for weapons, full-size downed poses, realm powers, 83-check validation and the latest download name. The rest of this document records the first forest pass.

The main game now opens the forest encounter. Double-click `Play.cmd` in the project, or extract `builds/Dark-Forest-Gauntlet-Playtest.zip` and run the contained `Play.cmd`. The older `Play-Gnome-Trial.cmd` still opens the original static Universal sprite inspection scene.

## Included

- Four selectable realm gnomes using their supplied illustrated sprites. Cut-paper puppet poses update at 10 Hz while movement and combat simulate smoothly. The upper body and two boot regions move independently, with idle breathing, walking, attack anticipation/recovery, hurt tint and a downed squash. These are runtime puppet animations, not newly painted frame-by-frame weapon or death sequences. The common puppet also supports the Universal sheet.
- Ember sweep: 20 damage, 4-unit range, 0.55-second cadence. Ironbark bolt: 22 damage, nearest visible target within 11 units, 0.7-second cadence. Spore clouds: 6 damage each 0.6 seconds, 2.8-unit radius, 3-second duration, max three clouds, slowing enemies; 1.1-second cast cadence. Light bolt: 16 damage, target range 8, 0.9-second cadence, heals 4 HP to living allies within 4 units. All casts have a 0.12-second windup. Walls block targeting and projectiles.
- Kenney CC0 forest models: trees, rocks, stumps, logs, bushes, grass and mushrooms. Original procedural ground shader, stepped root creatures, player markers, attack rings, bolts, damage/healing numbers and lighting.
- Kenney grass footsteps and wood impact sounds, plus a quiet original synthesized looping ambience bed.
- Class-selection lobby, four player health displays, controller disconnect status, pause/resume, restart, master volume saved locally, fullscreen toggle, quit and completion/failure menus.
- Existing local co-op rules: one keyboard plus up to three controllers, held attacks, manual revive, two spawning Hearts, Rootling cap, Golden Pear and all-survivor exit.

## Controls

| Action | Keyboard | Controller |
| --- | --- | --- |
| Move | WASD | Left stick / D-pad |
| Select class in lobby | 1–4 / Q / click | LB / RB |
| Join | P1 automatic | Start |
| Begin | Enter / click | Y |
| Attack | Hold Space | Hold X |
| Revive ally | Hold E nearby | Hold A nearby |
| Pause | Esc | Start after lobby |
| Restart after outcome | R / menu | Back / menu |
| Fullscreen | F11 / menu | Menu |

## Verification performed

- Godot 4.7.2: 34 baseline checks and 25 new realm checks pass. Run `tools/Test.ps1` after asset import.
- Automated movement-driven solo routes complete for all four classes: Ember 23.5s, Ironbark 27.1s, Spore 27.6s, Light 50.8s of simulation. These idealized routes establish reachability and solo viability, not human difficulty or expected playtime. Run `tests/solo_playthrough.gd` with `--headless --fixed-fps 60`.
- OpenGL renders inspected for lobby, four-player party, active combat, pause, walking poses and 960×540 layout. Captures and an animated GIF are under `artifacts/polish/`. Four-player capture uses simulated disconnected device slots; it does not test physical controllers.
- Portable PCK loaded and rendered from its own directory with the bundled Godot executable. This is an editor-runtime playtest bundle, larger than a standard release export. It does not need source files or a preinstalled Godot editor.
- 17 GLB models and five Ogg files passed header, license, SHA-256 copied-byte checks; GLBs also passed a 15k-triangle-per-file budget and embedded-dependency checks. Included source textures are embedded in the models. Only selected files were admitted. The user authorized local verification because game-dev CLI was unavailable. Receipts and licenses are under `assets/vendor/`.

## Remaining before a release

Physical controller joins/reconnects, human co-op playthroughs, longer-session balance and hardware performance testing remain necessary. The camera can still zoom far out when players separate widely. The current art combines illustrated gnomes and low-poly scenery; it is an integrated first art pass, not a final art-direction approval. More expressive hand/weapon animation, a proper fallen pose, richer sound design, accessibility/remapping and a conventional release export are later polish work. No bosses, additional playable realms, online play, procedural generation or progression/save system are included.

## Sources

Kenney Nature Kit 2.1: https://kenney.nl/assets/nature-kit — CC0-1.0.
Kenney Impact Sounds 1.0: https://kenney.nl/assets/impact-sounds — CC0-1.0.
Godot runtime: engine-provided MIT license and third-party notices included in the portable bundle.

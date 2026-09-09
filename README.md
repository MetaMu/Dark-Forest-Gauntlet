# Dark Forest Gauntlet

A Godot 4.7.2 / GDScript local co-op greybox: destroy two spawning Root Hearts and the remaining Rootlings, collect the Golden Pear, then bring every survivor through the Root Gate.

## Play

Double-click **Play.cmd** in the prepared local workspace, or import `project.godot` in Godot 4.7.2 and press F5. A fresh checkout needs the standard Windows Godot download extracted into `tools/godot`, or an independently installed editor. Engine binaries are not committed.

| Action | Keyboard (P1) | Controller (P2–P4) |
| --- | --- | --- |
| Move | WASD | Left stick / D-pad |
| Join in lobby | Automatic | Start |
| Begin | Enter | Y / top face button |
| Basic radial attack | Hold Space | Hold X / left face button |
| Revive nearby ally | Hold E for 2 seconds | Hold A / bottom face button |
| Restart after win/loss | R | Back / Select |

Join before starting; the roster locks during combat. Restart returns to the lobby, where controllers rejoin. Disconnected controllers retain their slots and stop moving; actual reconnect behavior needs hardware testing.

All class names currently share one attack. Move close and attack. Rootlings glow before striking: move away to dodge. A teammate can revive a downed ally; all players down simultaneously ends the run. After collecting the Golden Pear, move the whole surviving party through the gate to the far side.

## Implemented

Shared camera, wall collision, input ownership, health/damage, attack cooldowns, immunity, downed/revive states, two timed Root Heart spawners, ten-Rootling cap, pursuing enemies with telegraphed melee, reward/gate progression, all-survivor victory, failure and restart. Models remain named capsule/sphere/box placeholders.

## Verification

Run `tools/Test.ps1` in PowerShell. The latest engine-level regression run passed **34 checks** covering movement, collision, framing, slot ownership, combat, revival, spawning, enemy attacks and encounter progression. Import and headless smoke checks passed. A rendered 1280×720 capture was inspected.

Still requires hands-on tests: actual controllers/reconnects, a full human playthrough, balance, small-window HUD and restart UX. No standalone exported release is included.

## Next

See [ROADMAP](docs/ROADMAP.md) and [handoff audit](docs/HANDOFF_AUDIT.md). Next: solo and couch co-op playtests, then class selection and distinct attacks, followed by approved GLB/animation integration.

Supplied art remains locally in `reference/Dark_Forest_Gauntlet_FULL_CODEX_PACKAGE` and `Character Sprites`. Original files are preserved, excluded from Godot imports and this source milestone. No third-party art was downloaded. Production art, class abilities, obstacle navigation, final audio/VFX, bosses, online multiplayer and procedural generation remain pending.

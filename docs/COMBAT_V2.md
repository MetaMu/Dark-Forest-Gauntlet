# Combat v2 — 2026-09-10

This pass prioritizes the user's feedback: combat and powers. Start the project with Play.cmd or extract builds/Dark-Forest-Gauntlet-Combat-v2.zip and run its Play.cmd. The in-game header identifies COMBAT v2.

## Realm powers

Press Shift (keyboard) or B (controller). A press activates once; holding does not repeat. Powers require a living player in combat. Cooldowns pause with the game and appear below each health bar.

| Class | Power | Behavior | Cooldown |
| --- | --- | --- | --- |
| Ember | Dash burst | Physics-based 0.18s dash at 16 units/s, brief protection, 35-damage landing burst within 3 units; walls stop movement and damage | 7s |
| Ironbark | Piercing volley | Three 25-damage arrows; each can hit up to three different enemies; walls stop arrows | 9s |
| Spore | Root snare | 15 damage and 2.5s immobilization for mobile enemies within 5 units; 4s slow; walls block it | 10s |
| Light | Sanctuary | Heal living allies by up to 25 HP or revive fallen allies to 40 HP within 5 units; brief protection; walls block it | 14s |

Basic attacks retain the previous values. Light's basic healing cannot revive; Sanctuary explicitly can. All classes can still manually revive with E/A. Auto-aim chooses a nearby visible enemy when a weapon attack or power begins; the ranged basic projectile also checks its target when released. Ember's burst lands at the actual dash endpoint.

## Animation and feedback

Original code-native flat mesh weapons match the cut-paper presentation: axe, bow with moving string/arrow, mushroom staff, radiant staff. Weapon windup/release/recovery poses run at the same 10 Hz cadence as the gnomes. The gnome falls sideways at full proportions over three pose steps, drops the weapon, shows a revive marker, and rises on revival. This is a puppet pose, not a newly painted death sequence. Hits produce short-lived sparks, an impact sound and a brief enemy recoil pose. No global time slowdown was added.

The camera now computes its required size from both feet and overhead markers and reserves room for the HUD. This keeps separated players in view, but they will still appear smaller when spread far apart.

## Validation

83 automated checks: 34 baseline, 25 realm, 24 new power/pose/camera checks. Powered solo routes for all four classes reach victory. New checks cover cooldown/held-input enforcement, dash collisions and landing damage, volley creation, root duration and movement, healing/revival range, no casting while downed, full-size fall and recovery, and camera bounds. Render captures are in artifacts/polish-v2. These are deterministic engineering checks, not physical controller or human balance tests.

## Human playtest focus

Try each realm's basic attack and power against both a Root Heart and a group of Rootlings. Note whether the power feels useful, whether the cooldown is understandable, and whether the weapon motion clearly matches the impact. In co-op, try a manual revive and a Sanctuary revive. Report the class, what you pressed, what you expected, and what happened.

No additional third-party downloads were introduced in this pass. Existing Kenney assets and licenses are retained. The portable bundle continues to use the existing Godot runtime plus a PCK; it is a playtest distribution, not a conventional optimized release export.

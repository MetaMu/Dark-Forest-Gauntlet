# Four-realm power effects — v3

Implemented September 10, 2026 from [the power-effects research](POWER_FX_RESEARCH.md).

## Play or watch

In the project, double-click **Play.cmd** to play or **Play-Power-Showcase.cmd** to watch four characters cast automatically. Close the showcase window to exit it.

For a portable copy, extract **builds/Dark-Forest-Gauntlet-Power-FX-v3.zip** completely, then open **Play.cmd** or **Watch-Powers.cmd**. Windows x64 with OpenGL 3.3 is required. The bundle includes its runtime; this is an editor-runtime playtest, not a conventional release-template export.

In normal play, choose a character with **1–4** before pressing **Enter**. Move with **WASD**, attack with **Space**, and cast the realm power with **Shift**. One keyboard player and up to three controllers can join. The automatic showcase needs no controllers: it stages the four actual class instances and durable review enemies, and triggers their normal power methods. Its arrangement and enemy health are for visual review, not balance testing.

## What changed

| Character | Power presentation |
| --- | --- |
| Ember Hollow | Flames follow the dash path, with brief puppet afterimages. Landing produces a broken expanding fire wave, a bright core, embers and fading smoke. Basic attacks use small flame sweeps. |
| Ironbark | Three sharp, pale arrowheads have tapered green trails. Confirmed contacts produce a short flash and splinters; arrows retain piercing behavior. |
| Spore Grove | A brief irregular violet pulse marks the snare area. Wooden roots coil around affected enemies and follow them. Roots disappear with the actual root status; faint motes remain during the slower movement phase. Basic clouds use soft smoke. |
| Light Realm | A fine golden Sanctuary pattern, rising light, traveling healing pulses and personal halos mark the cast and healed or revived allies. The brief visuals end within the existing protection period. |

Damage, range, cooldowns, healing, revival and status durations retain their prior values. The four playable characters remain Ember Hollow, Ironbark, Spore Grove and Light Realm. Universal remains available in the separate sprite inspection trial.

## Sources and implementation

Nine original transparent textures were imported from [Kenney Particle Pack](https://kenney.nl/assets/particle-pack) and [RPicster's Godot particle and VFX textures](https://github.com/RPicster/Godot-particle-and-vfx-textures). Both are CC0. Kenney textures are 512×512; RPicster textures are 256×256 and pinned to commit `9bb6fe7cc50534e171d2093630f3288773c8c865`.

The selected files, original licenses and source/SHA-256 receipt are in `assets/vendor/power-fx/`. The project-local import follows the approved alternative to the unavailable game-dev CLI. No paid service or runtime effects plugin is required. Existing sounds remain in use.

The effects use depth-tested mesh particles, procedural ground patterns and short mesh trails in Godot's Compatibility renderer. They retain the project's stepped gnome animation. Target-attached roots read the real status timers, while scene and encounter cleanup remove transient effects.

## Review and validation

- `tools/Test.ps1`: **96 passing checks** — 34 baseline, 25 realm, 24 power/animation and 13 VFX lifecycle checks. Engine and shader errors cause a failure.
- Lifecycle coverage includes eligible targets, status expiry, repeated casts, early removal, death, actual healing/revival, overlapping effects and scene teardown.
- Actual 1280×720 renderer captures cover each class, overlapping casts and a darker ground position, at gameplay's minimum camera size of 19. A 36-frame GIF shows the overlap in motion.
- `node tools/make-power-fx-review.cjs` verifies all nine texture hashes, licenses, dimensions and alpha channels, then builds the review sheet, animation and hashed artifact manifest.
- `tools/Package-MoonlitRuins.ps1 -PowerFX` exports the new playtest, runs ordinary-start and four-character showcase smoke checks, includes licenses and receipts, and verifies every packaged file against its SHA-256 manifest.

Review files live in `artifacts/power-fx-v3/`. `timing.json` records 45 idle and 45 simultaneous-cast samples. These are local frame-completion measurements with a fixed 60 Hz simulation, including CPU/render waits; they are not isolated GPU timings or a hardware performance guarantee.

This is a first integrated effects pass. Physical four-controller play, other graphics hardware and human feedback on overlapping combat remain useful next checks. The current illustrated puppets and game rules are still those of the existing Moonlit Ruins playtest.

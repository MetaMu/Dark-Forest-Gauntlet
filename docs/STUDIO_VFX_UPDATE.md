# Studio magic update — September 14, 2026

The Game Updates Studio handoff is now implemented and reviewed in the Gauntlet's native Godot Compatibility renderer. The previous audit remains a historical record; this pass repairs its confirmed glint defect and supplies the missing geometry.

## Changes

- **Projectile wakes:** sparks originate at the moving projectile, with each particle's delay measured from its own emission time. Small six-sided shards appear every second emission. Both sparks and shards fade behind the bolt rather than appearing at world origin or being born expired.
- **Spore Grove:** a three-crystal cluster and seven small rising shards accompany the rune. These are closed, faceted meshes, not flat texture planes. The cluster is offset from the caster so it does not cover the gnome. Existing roots still follow the actual enemy status timer.
- **Ember Hollow:** retained and visually checked the three short landing coils, bright impact core, flame trail and local light pulse.
- **Light Realm:** retained and visually checked the star layer, solar beams, healing halos and rising motes.

The crystal cluster is cosmetic and disappears within the cast. It does not imply a new attack, summon or persistent obstacle. Damage, targeting, range, healing, cooldowns, status duration and controls were not changed. No new renderer, camera input, third-party texture or external runtime was installed.

## Provenance

The shared Studio's September 14 `GAME-UPDATES-STUDIO.md` and `ELEMENTAL-SANDBOX-AUDIT.md` identify [Elemental Sandbox](https://github.com/achrefelouafi/HandCastAbilityThreeJS) as the MIT-licensed visual reference. Its spell silhouettes, runes and crystal language informed this adaptation. This pass uses original GDScript mesh construction and the game's existing shaders; it does not copy the reference's JavaScript, GLSL, models or hand-tracking runtime. No upstream commit was pinned by the original Studio handoff, so exact upstream revision parity is not claimed.

The nine Kenney/RPicster textures remain unchanged and match their existing SHA-256 receipt. Their original CC0 license files and asset receipts accompany the build. This document accompanies the build as the adaptation credit.

## Verification and limits

- `tools/Test.ps1`: **180 checks**, including 12 new renderer checks for revision identity, late glint visibility, off-origin coordinates, faceted wakes, bounded allocation, depth testing and cleanup.
- Four individual power captures, simultaneous casts and a dark-ground capture are in `artifacts/studio-vfx/`. These are actual game-renderer captures with staged, durable review targets. They are presentation evidence, not combat balance tests.
- `Studio-Powers-Preview.gif` shows staggered casts by all four characters. Each frame is sampled from the actual renderer.
- On this machine, the 45 sampled simultaneous-cast frames had median completion spacing 7.8 ms and p95 12.661 ms. These are fixed-simulation capture measurements including CPU/render waits, not isolated GPU timings or a hardware-wide performance promise.
- `evidence-hashes.json` ties the captured images to the reviewed scripts.
- The Studio build runs normal play, keyboard co-op, direct level two and the power showcase. The targeted 12-check suite is also run against the exported PCK, ensuring the distribution contains the repaired revision, not merely a fresh archive date.

## Play

Extract **Dark-Forest-Gauntlet-Studio-VFX.zip** completely. Open **Play-Keyboard-Coop.cmd** for two keyboard players, **Play.cmd** for solo/controllers, or **Watch-Powers.cmd** for the automatic four-gnome showcase. Both levels and Maria's existing in-game celebration remain included. The separately requested 50-frame Maria GIF is included as a standalone asset; the victory-scroll animation was not changed by this effects pass.

Runtime marker: `2026-09-14-crystal-wake-1`. This remains a Windows editor-runtime playtest export.

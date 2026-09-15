# Game Studio magic audit — September 14, 2026

**Follow-up:** the findings below record the pre-repair state. See [Studio VFX update](STUDIO_VFX_UPDATE.md) for the glint repair, actual crystal geometry, new renderer checks and refreshed distribution.

## Verdict

The working Godot project contains the September 14 Studio adaptation. The latest downloadable Celebration build does not contain the new projectile-glint property and predates that update. The source update also has a confirmed glint rendering defect. Asset presence is therefore confirmed; complete, working delivery is not.

Scope: compared the local sibling project's `GAME-UPDATES-STUDIO.md` and `ELEMENTAL-SANDBOX-AUDIT.md`, Gauntlet source, recorded texture receipts, current regression suite, and `builds/Celebration-Playtest/DarkForestGauntlet.pck`. This is an audit of the latest locally recorded Studio handoff, not a claim to have checked every upstream repository for newer releases. No gameplay or production VFX code was changed by this audit.

## Findings

1. **High: portable build is stale.** The Studio log records its adaptation on September 14; the Celebration archive was built September 12. A Godot probe of the packaged script's property list confirms `glint_clock` is absent. Its source text is stripped, so missing source-string matches were not used as proof. The inspected PCK matches its distribution manifest SHA-256: `ea92b3784c2e894dcddfef22dec214411912ba5c2bed5f99d108c19f80251328`. Playing the project via its root launcher uses the updated source; playing the old download does not deliver this latest pass. Rebuild and smoke-test a new distribution after fixing the defect below.

2. **High: projectile glints use world origin and expire against the trail's age.** `scripts/realm_vfx.gd`, `update_trail()`, adds each spark at `Vector3.ZERO` with delay zero. The trail effect itself is positioned at world origin; its ribbon vertices use global projectile coordinates. The newly added sprites do not. `_process()` computes particle age as `age - delay`, so new sparks added after trail age 0.18 s are immediately invisible. A production-renderer probe at trail age 0.383 s found four allocated glints, zero visible; the last glint origin was `(0,0,0)` while the bolt was `(12.4,1,10)`. Fix by using the projectile position transformed into effect-local coordinates and the current effect age as emission delay. Add a regression that asserts late-emitted glints remain visible near a moving projectile far from origin.

3. **Medium: local handoff documentation and shipped attribution are incomplete.** The native script credits the Elemental Sandbox URL and identifies its MIT provenance. The Gauntlet magic guide still describes September 12 and 133 tests; its packaged notes refer to that older pass. There is no accompanying Elemental handoff/provenance document in this game's vendor directory or packaging workflow. The Studio describes original motif adaptations, not copied Three.js/GLSL code. Record that distinction, the exact reviewed source revision when available, and include the adaptation credit in the next distribution. Existing CC0 texture licenses are present.

## Confirmed integrations

| Resource or behavior | Result |
| --- | --- |
| Kenney / RPicster particle textures | All nine files match recorded SHA-256 hashes; CC0 receipts and original license files present |
| Ember landing coils | Present in `ember_impact()` and called by the actual landing event |
| Spore rune motif | Present in `snare_cast()` and called by the real power; crystal-heart wording describes a texture motif, not an imported 3D crystal model |
| Sanctuary star/mote layering | Present in `sanctuary()` and called by the actual power |
| Projectile glints | Wired into the actual projectile trail, but defective as described above |
| Earlier Tower Defense lighting | Six-light budget, rise/peak/echo/fade envelope and depth-tested VFX retained |
| Three.js / MediaPipe runtime | Not inserted into the Godot effects; adaptation stays native |

No new canonical asset package was admitted. The game-dev CLI is unavailable; existing receipts were verified directly, consistent with the previously authorized local-import workflow.

## Reproducible evidence

- `artifacts/studio-audit/source.log`: production-renderer glint probe.
- `artifacts/studio-audit/pack.log`: packaged-script property probe.
- `artifacts/studio-audit/texture-hashes.json`: nine texture integrity results.
- `artifacts/studio-audit/build-hash.json`: inspected PCK matches its distribution manifest.
- `artifacts/studio-audit/tests.log`: existing suite output. Existing lifecycle checks do not assert new glint position or late-emission visibility, so passing them does not clear that defect.
- `tests/studio_vfx_audit.gd`: read-only runtime probe; not added as a passing regression to hide the defect.

Recommended completion order: repair glint placement/timing, add the targeted visual-behavior check, capture all four powers, refresh the local provenance/guide, then export and verify a new downloadable build.

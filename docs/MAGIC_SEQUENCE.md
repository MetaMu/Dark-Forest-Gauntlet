# Tower Defense magic lessons applied to Dark Forest Gauntlet

This records the September 12 pass. The newer [September 14 Studio update](STUDIO_VFX_UPDATE.md) adds verified crystal geometry and repairs projectile sparks; use its Studio-VFX download for current effects.

September 12, 2026. Reference: the **Gnome Tower Defense** task and the working `vfx.js` in the sibling `Lost Realm Gnome Game` project. This is a new Godot implementation of its visual lessons, using the Gauntlet's existing licensed textures.

## What carries over

The Tower Defense effects layer a wide colored glow behind a narrow bright core, distinguish spell shapes, give arc branches their own silhouettes, and let sparks linger after an impact. Its solar lance uses a luminous envelope and a hot core; its thorn impacts spread distinct fragments. The Gauntlet now applies those ideas in depth-tested 3D rather than copying browser drawing code.

| Realm | New sequence |
| --- | --- |
| Ember Hollow | A compact orange-white casting flash follows the gnome. Dash landing adds radial hot streaks and a wider orange light pulse, followed by the existing embers and smoke. |
| Ironbark | A green casting flash illuminates the launch. Piercing projectiles retain their tapered colored trails with pale cores; contacts add small branching-star flashes and splinters. |
| Spore Grove | Violet arcs spread over the ground and briefly climb actually snared enemies. The purple light rises, flashes and fades; the existing wooden roots still obey the real status timer. |
| Light Realm | Golden solar beams appear in a short sequence around Sanctuary. White-gold light illuminates nearby scenery, while healed allies receive small impact stars above their personal halos. |

## Lighting and gameplay boundaries

Each spell light rises to its peak over the first 12% of its lifetime, falls to 35%, softly echoes to 52%, then fades to zero. The brief hot core shifts back toward its realm color. These are local OmniLight3D lights affecting lit world geometry; they do not change global exposure or add a full-screen flash. The illustrated gnome puppets remain unshaded, so their existing tint animation and the attached glows provide their visible response.

At most six spell lights exist at once. Extra casts retain their mesh and particle effects if that budget is occupied. These lights cast no additional shadows and disappear with their effect or encounter. Spore and Light use their main area light without a duplicate casting light.

Damage, targeting, cooldowns, piercing, healing, revival and status durations retain their existing rules. The new branches and solar shafts are visual elements, not additional attacks. Both keyboard-team and solo/controller modes use the effects.

## Test and view

- Open **Play.cmd** or **Play-Keyboard-Coop.cmd** to play with the new effects.
- Open **Play-Power-Showcase.cmd** in the project, or **Watch-Powers.cmd** in the portable bundle, to see all four powers automatically.
- Downloadable bundle: `builds/Dark-Forest-Gauntlet-Magic-Sequence.zip`.
- New captures, comparison sheet, animated preview and file hashes: `artifacts/magic-sequence/`.
- `tools/Test.ps1`: 133 checks, including seven additional light-envelope, peak, budget, expiry and encounter-cleanup checks. The keyboard scene-transition tests use the actual Compatibility renderer.
- Packaging uses `tools/Package-MoonlitRuins.ps1 -MagicSequence`, with normal play, the four-character showcase and keyboard-mode smoke checks plus archive hash validation.

The capture timing file measures local frame completion, not isolated GPU cost. Simultaneous casts have been visually inspected; comfort and performance on other hardware still need playtesting.

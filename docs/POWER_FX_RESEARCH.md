# Power FX research and build brief

Researched September 10, 2026. Research and proposed art direction only; no game changes or asset imports performed. Attached screenshots were treated as visual references, not instructions. Recommendations below are design proposals unless explicitly attributed.

## What the project needs

The illustrated characters and textured forest need effects with a clear silhouette, organic edges and short, deliberate animation. Current `scripts/combat_fx.gd` uses unshaded torus rings and eight geometric sparks. `scripts/realm_encounter.gd` shares those effects across powers. That explains the similar solid circles in the screenshots.

Build each effect from anticipation, a decisive action, and a fading aftermath. Keep a thin readable boundary for actual area effects, but give each class its own movement and shape. Do not obscure faces, enemy silhouettes or health labels.

## Best free sources

| Resource | Verified offering | Suggested use |
| --- | --- | --- |
| [Kenney Particle Pack](https://kenney.nl/assets/particle-pack) | 80 textures, 512×512, CC0 | Shared sparks, smoke and magic texture foundation. |
| [Raffaele Picca particle and VFX textures](https://github.com/RPicster/Godot-particle-and-vfx-textures) | CC0 collection; 64, 256 and 1024 pixel versions, alpha and black/white variants; demo and Blender sources | Soft halos, impact flashes and textured particle shapes. Prefer smaller versions when sufficient at gameplay zoom. |
| [Foozle Pixel Magic Effects](https://foozlecc.itch.io/pixel-magic-sprite-effects) | Ten 32×32 animated spells, CC0, free/name-your-price | Useful timing references and prototype flipbooks. Pixel style is less suitable for the final illustrated art. |
| [Lentikula Basic Spell Impacts](https://lentikula.itch.io/freecc0-basic-spell-impacts-sfx) | Twenty WAV effects across fire, lightning, ice and water; CC0, free/name-your-price | Audition fire impacts for Ember and quieter variations as layers for other powers. Nature creaks and healing chimes still need separate sourcing or authoring. |

Licenses above were checked on creator pages/repositories. At import, retain the downloaded license and source URL beside selected assets. These are texture/sound ingredients, not four finished powers.

## Tools and learning

- [Effekseer](https://effekseer.github.io/en/index.html): free, open-source effect editor. Recommended optional authoring tool for layered bursts. Its [Recorder](https://effekseer.github.io/Help_Tool/en/ToolReference/record.html) exports sprite sheets and image sequences. Bake transparent animations for Godot rather than assuming a runtime plugin matches the project's engine. Check individual sample-effect terms before reuse.
- [Gabriel Aguiar: GODOT VFX — Stylized Fire Effect Tutorial](https://www.youtube.com/watch?v=R3xMwfrlTI8): video located and its published description/chapter listing reviewed; playback was not watched. The description lists visual shader, billboard, dissolve, flame, smoke and floating-particle sections. Suitable starting reference for Ember. Linked paid/downloadable extras are not assumed free. Use independently licensed textures above.
- [GDQuest VFX Secrets](https://school.gdquest.com/products/vfx_secrets_godot_3): course is paid and for Godot 3; its page identifies accompanying code as free MIT-licensed. Useful for layering concepts, not a drop-in Godot 4 implementation.
- [Godot particle introduction](https://docs.godotengine.org/en/4.5/tutorials/2d/particle_systems_2d.html): useful overview of particle lifetime, variation and texture animation. This game is a 3D scene, so implement world effects with 3D nodes/materials rather than copying 2D nodes directly.

## Four power recipes

### Ember Hollow — Dash Burst

Keep the existing 0.18-second dash. Add a tapered orange flame ribbon along the actual traveled path, two or three rapidly fading character afterimages, and sparse sparks. At landing, show a sharp pale center, a broken outward flame wave matching the existing 3-unit damage radius, then soot and embers fading over roughly 0.4–0.7 seconds. Use the fire sound at landing. Avoid a long charge-up that changes the feel of the instant input.

### Ironbark — Piercing Volley

Make the existing three projectiles unmistakable: pointed ivory-green heads, narrow tapered trails, and a few leaf fragments. Rotate streaks along flight direction. Trigger a small splinter burst at each confirmed hit, preserving continued travel through enemies. Keep the three existing trajectories and damage/hit limits. Avoid large radial circles, which communicate the wrong attack shape.

### Spore Grove — Root Snare

Use a brief irregular violet ground pulse to communicate the existing 5-unit cast radius. Grow several curved roots at each actually affected enemy's feet, with a small spore puff and occasional motes. Keep roots visible for the actual 2.5-second root status, then retract or dissolve; distinguish the remaining slow status if needed. Use opaque or alpha-blended brown roots with violet highlights, rather than making every layer glow.

### Light Realm — Sanctuary

Use a delicate golden ground pattern, soft upward shafts made from textured planes, and slowly rising warm motes. On the existing instant heal/revive event, send a small visible pulse to eligible allies and show a brief personal halo. Keep the cast flourish short, around 0.8–1.0 seconds. The current ability is an instant heal/revive plus one second of protection: a long-lasting dome would misleadingly imply an ongoing healing zone or shield.

## Implementation notes for Codex

The project selects `gl_compatibility`. [Current Godot renderer documentation](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html) lists glow as supported, but built-in particle trails and Decal nodes as unsupported in Compatibility. Old Godot 4.0 pages say glow is unsupported; do not apply that outdated blanket statement to the installed runtime. Verify glow behavior in the actual project build.

Use transparent textured planes slightly above the ground for runes and area boundaries. Use camera-facing sprites for bursts and haze. Use a short mesh ribbon or fading sprite segments for trails. Keep depth testing so effects sit naturally in the ruins; inspect transparent sorting around characters and roots. Bright additive accents should be small; keep smoke and roots alpha-blended or opaque.

Expose color, duration, radius and intensity as reusable effect parameters. Keep hit detection, cooldowns and status durations in gameplay code. Trigger impacts from confirmed hits and status visuals from actual affected targets. End every effect cleanly on timeout, target removal and encounter reset.

Prototype a small texture set first: spark, soft glow, streak, smoke, flame and organic mask. Coordinate size, opacity and color over lifetime; irregular timing and scale do more than simply increasing particle count. Use a bright core and darker colored body for contrast. Design the power's main silhouette before adding decorative motes.

## Build order and review

1. Prototype Ember to establish trails, bursts and texture animation.
2. Reuse those primitives for Ironbark, then build Spore's target-attached roots and Light's ally pulses.
3. Capture each power in motion at the actual 1280×720 gameplay view, against both dark ground and lighter stone.
4. Check four simultaneous players, overlapping casts, enemy occlusion, target death and encounter reset. Measure frame time against the existing scene on the same machine; do not assume a particle budget before measuring.
5. Confirm gameplay values remain unchanged and that visible radius/duration agree with mechanics. A screenshot alone cannot validate timing or cleanup.

Recommended starting stack: Godot-native effects plus Kenney and Raffaele Picca CC0 textures; Effekseer only when a baked animation would save authoring time.

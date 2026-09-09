# Path to the first playable

Work proceeds in bounded milestones. The first deliverable is one complete greybox encounter, not final art or the full game.

1. **Foundation validation** — portable Godot 4.7.2, project import, movement/collision tests, independent input ownership and camera checks.
2. **Combat loop** — health, basic attack, enemy pursuit, downed/revive states, restart. Balance and controls remain provisional because the source input/combat specs were absent.
3. **Corrupted Clearing** — two destructible Root Hearts with bounded spawning, remaining-enemy cleanup, Golden Pear, physical gate, all-survivors exit and all-downed failure.
4. **Playable handoff** — regression tests, runnable launcher, documented controls/limitations, GitHub source milestone.
5. **Class identity and feel** — class selection, Ember melee / Ironbark ranged / Spore control / Light healing, hit feedback and balance through controller playtesting.
6. **Art integration** — approved GLBs and animations replace named placeholders; final forest kit, HUD, VFX and audio follow. Preserve supplied art direction.

## Acceptance gate for this implementation pass

- Import and run without script errors in the installed engine.
- Programmatic checks cover movement, player slot ownership, damage, revival, spawning and win/loss progression.
- One encounter can advance from combat to reward to exit, with a restart after win or loss.
- Keep manual controller/visual playtesting explicitly outstanding where it cannot be exercised.
- Record actual results, not just intended behavior.

Online multiplayer, procedural generation, bosses, additional realms and production art are later milestones.

## Current checkpoint

Milestones 1–3 are implemented with a clean import, smoke run, 34 passing engine-level checks and an inspected rendered capture. Milestone 4 includes the launcher and validation instructions; GitHub publication is the final handoff step. Physical controllers and human playtesting remain open.

Next bounded task: play one solo run and one couch co-op run, record combat readability/controller issues, then implement class selection and distinct basic attacks before production models.

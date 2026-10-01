# Atlas gnome chest — Dark Forest Gauntlet

`gnome_chest_hinged.glb` is the game-ready, animated owner-supplied Atlas chest. `scripts/forest_art.gd` places it in the Moonlit Ruins. `scripts/atlas_chest.gd` opens it once when a nearby controlled player uses the existing Interact binding. This is a visual interaction; no loot or reward mechanics were added.

The untouched Atlas source, editable Blender file, build script, and before/after previews are archived inside this game at `reference/production/chest/`. The original source SHA-256 is `5BE0FB47203CD66BEA472D6618CBD66BBCCBA7BC302AD444BFD0989D415827B1`.

The runtime mesh has about 61,800 triangles, three 2K PBR textures, tangents, and a 30-frame `OpenChest` animation. Godot may extract the embedded textures alongside the GLB during import. Retain those extracted source images with the GLB. Do not redistribute outside the owner's game without checking the Atlas terms that apply to their account and generation.

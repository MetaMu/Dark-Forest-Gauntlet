# Universal gnome gameplay-size trial

Run `Play-Gnome-Trial.cmd` from the project folder, or run `scenes/gnome_sprite_trial.tscn` in Godot. WASD moves; keys 1–4 select front, right side, back and right three-quarter. Existing encounter controls still apply. The main game scene is unchanged.

The trial uses a depth-tested, unshaded Sprite3D billboard, 2.2 world units tall. Its 512-pixel frame has a 416-pixel silhouette; pixel_size is 2.2/416. Sprite3D offset (0,208) maps the foot baseline to the player's origin. This positive Y offset is specific to Sprite3D; the negative Y offset documented for Sprite2D follows its screen coordinate convention. The original collision capsule is unchanged. The sprite stays camera-facing and inherits the existing downed/revive squash through the trial script. View selection is manual; no walk animation or automatic direction selection is implied.

Validation on 2026-09-09: Godot 4.7.2 OpenGL compatibility renderer on NVIDIA RTX 4070 Laptop GPU, viewport 1280×720, camera size 24. The character appears approximately 66 pixels tall. Transparency, foot placement, and scenery occlusion were visually inspected in engine captures. The player label was raised after its initial overlap with the hat. The silhouette and costume colors read at this size; fine facial details remain small. This is a single-player baseline, not approval of readability at maximum co-op camera spread.

The capture test passed 12 checks, including four view exports, movement, downed/revive state, texture dimensions and depth settings. Six PNG captures and a JSON report are in `artifacts/gnome-trial/`. This uses the game's own viewport capture; no game-dev adapter or sealed capture harness is installed.

The existing regression suite passed all 34 checks after replacing three stale exit test coordinates (-10.5) with EXIT_Z - 0.5. The production exit is at -22; gameplay code was not changed for this correction.

Reproduce captures with the local Godot console executable: `--path . --script tests/gnome_sprite_trial.gd --position -2000,-2000 --resolution 1280x720`. Requires a graphical renderer; headless mode cannot produce these viewport images.

Next art milestone: author and test a Universal idle and walk cycle, with feet and silhouette aligned to this export contract. Check motion and four-player camera readability before producing all realm animations. Attacks, hurt and a proper downed pose follow; the current squash is a gameplay placeholder.

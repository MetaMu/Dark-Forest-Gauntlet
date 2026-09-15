# Maria's 50-pose victory celebration

The final exit of level two now opens the victory scroll with the approved fifty-pose animation. Each frame comes from a different generated pose, including crouching, two-handed takeoff, airborne kicks and arm pumps, landing, and a return to rest. The old programmed body bob and stretch have been removed.

The game reads one 3200 × 1600 cutout atlas with ten columns and five rows. Poses use 60 ms holds, with 120 ms on the opening and closing poses, for a 3.12-second loop. Jump height is authored into the atlas; the runtime does not add another jump or interpolate body poses. Parchment, confetti, replay and quit controls remain.

## Source and provenance

`assets/characters/maria/dynamic-50/` contains the production atlas, per-frame metadata and hashes, ImageGen prompts, and layout-correction prompt. Artwork was generated through the built-in ImageGen tool, using Maria's existing club sprite as the identity reference. Generated checkerboard backgrounds were corrected to white through ImageGen before standard sprite slicing and registration. These are rendered sprite poses, not an editable rigged 3D model.

The source sheets, 640 × 640 individual PNGs, standalone GIF and original asset ZIP remain in `artifacts/maria-dynamic-50/` locally. Generated review output and Windows build binaries are intentionally excluded from Git; production game assets are committed.

## Play and verify

Extract `builds/Dark-Forest-Gauntlet-Dynamic-Maria.zip` and open `Play-Keyboard-Coop.cmd`, or `Play.cmd` for solo/controllers. Collect level one's pear to start level two; clear level two, collect its pear, and bring the surviving gnomes through the north exit.

Validation: 183 source checks, including all fifty frame indices and the loop boundary. The exported PCK also runs the 15 campaign checks and 12 targeted Studio VFX checks. `artifacts/celebration/preview.png` and `frame-00.png` through `frame-49.png` show the animation on the actual in-game scroll.

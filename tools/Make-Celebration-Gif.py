"""Assemble the game's deterministic 24-frame, two-second UI loop for review."""
from pathlib import Path
from PIL import Image

folder = Path(__file__).resolve().parents[1] / 'artifacts' / 'celebration'
frames = [Image.open(folder / f'frame-{i:02}.png').convert('RGB') for i in range(24)]
# A common palette avoids palette shimmer; timing sums to exactly 2000 ms.
palette = frames[9].quantize(colors=256)
indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
indexed[0].save(folder / 'Maria-Victory-Loop.gif', save_all=True,
                append_images=indexed[1:], duration=[80, 80, 90] * 8,
                loop=0, disposal=2, optimize=False)
with Image.open(folder / 'Maria-Victory-Loop.gif') as result:
    assert result.n_frames == 24 and result.info['loop'] == 0
    total = 0
    for i in range(result.n_frames):
        result.seek(i)
        total += result.info['duration']
    assert total == 2000
print('Verified: 24 frames, 2000 ms, infinite loop')

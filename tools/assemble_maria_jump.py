"""Encode ten native Godot animation renders as a transparent, infinitely looping GIF."""
from pathlib import Path
from PIL import Image
import json
import sys

count = 50 if '--smooth' in sys.argv else 10
folder = Path(__file__).resolve().parents[1] / 'artifacts' / f'maria-jump-{count}'
frames = [Image.open(folder / f'frame-{i:02}.png').convert('RGBA') for i in range(1, count+1)]
atlas = Image.new('RGB', (640 * count, 640), '#eee0b9')
for i, frame in enumerate(frames):
    atlas.paste(frame, (640*i, 0), frame)
palette = atlas.quantize(colors=255)
indexed = []
for frame in frames:
    rgb = Image.new('RGB', frame.size, '#eee0b9')
    rgb.paste(frame, mask=frame.getchannel('A'))
    encoded = rgb.quantize(palette=palette, dither=Image.Dither.NONE)
    encoded.paste(255, mask=frame.getchannel('A').point(lambda a: 255 if a < 128 else 0))
    encoded.info['transparency'] = 255
    indexed.append(encoded)
durations = [180, 100, 80, 100, 180, 100, 100, 100, 100, 160]
if count == 50:
    durations = [40] * count
out = folder / f'Maria-3D-Jump-{count}-Frame.gif'
indexed[0].save(out, save_all=True, append_images=indexed[1:], duration=durations,
                loop=0, transparency=255, disposal=2, optimize=False)
with Image.open(out) as gif:
    assert gif.n_frames == count and gif.info['loop'] == 0
    assert gif.size == (640, 640)
    for i in range(count):
        gif.seek(i)
        assert gif.info['duration'] == durations[i]
contact = Image.new('RGB', (320*5, 320*2), '#eee0b9')
for i, frame in enumerate(frames[::count//10]):
    tile = frame.resize((320,320), Image.Resampling.LANCZOS)
    contact.paste(tile, ((i%5)*320,(i//5)*320), tile)
contact.save(folder / 'contact.png')
(folder / 'animation.json').write_text(json.dumps({'frames':count,'size':[640,640],
    'duration_ms':sum(durations),'frame_durations_ms':durations,'loop':'infinite',
    'source':'Existing Maria 3D-rendered sprites; native Godot pose animation'},indent=2))
print(f'VERIFIED: {count} frames, {sum(durations)} ms, transparent, infinite loop: {out}')

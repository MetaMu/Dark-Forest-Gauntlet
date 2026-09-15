"""Slice ImageGen's fifty distinct poses, register them, and encode the celebration.

No new body poses are synthesized here: every frame comes from a different sheet cell.
Connected-component slicing preserves arrows crossing nominal row boundaries.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import numpy as np
import json, hashlib, shutil, zipfile

root=Path(__file__).resolve().parents[1]
out=root/'artifacts/maria-dynamic-50'
source=Path(r'C:/Users/rosec/.codex/generated_images/01a0872a-1cfe-7210-85e4-4f1c892afdb7')
names=['exec-60fa0af7-b181-4e36-9cda-1bcf492a11a8.png','exec-8784faae-dd5e-4226-910f-1e2ac0ad1513.png','exec-70969b9d-5b56-463a-8a58-816a32b8c216.png','exec-3b006649-be2b-406a-8452-1d0febd0ac1f.png','exec-385a861c-1353-4149-93e5-6f4b16b1bd8d.png']
(out/'sheets').mkdir(parents=True,exist_ok=True)
(out/'frames').mkdir(exist_ok=True)
frames=[];records=[]
for sheet_index,name in enumerate(names):
    dest=out/'sheets'/f'maria-poses-{sheet_index*10+1:02}-{sheet_index*10+10:02}.png'
    shutil.copy2(source/name,dest)
    sheet=Image.open(dest).convert('RGB')
    w,h=sheet.size
    for row in range(2):
        for col in range(5):
            index=sheet_index*10+row*5+col
            strip=sheet.crop((round(col*w/5),0,round((col+1)*w/5),h))
            pixels=np.asarray(strip)
            foreground=np.min(pixels,axis=2)<225
            mask=Image.fromarray((foreground*255).astype('uint8')).copy()
            # Find a red jacket/hat seed within the intended row.
            red=(pixels[:,:,0]>150)&(pixels[:,:,0]>pixels[:,:,1].astype(float)*1.3)&(pixels[:,:,0]>pixels[:,:,2].astype(float)*1.1)
            region=np.zeros(red.shape,dtype=bool)
            region[int((row+.30)*h/2):int((row+.78)*h/2),int(strip.width*.25):int(strip.width*.8)]=True
            ys,xs=np.where(red&region)
            assert len(xs)>100, (index,'no character seed')
            center=np.array([np.median(xs),np.median(ys)])
            chosen=np.argmin((xs-center[0])**2+(ys-center[1])**2)
            ImageDraw.floodfill(mask,(int(xs[chosen]),int(ys[chosen])),128)
            component=np.asarray(mask)==128
            component_image=Image.fromarray((component*255).astype('uint8'))
            # Fill enclosed whites (eyes, beard, arrow feather) without retaining the backdrop.
            hole_map=component_image.copy()
            ImageDraw.floodfill(hole_map,(0,0),128)
            solid=Image.fromarray(((np.asarray(hole_map)!=128)*255).astype('uint8'))
            bbox=solid.getbbox();assert bbox and (bbox[3]-bbox[1])>180,(index,bbox)
            rgba=strip.convert('RGBA');rgba.putalpha(solid)
            crop=rgba.crop(bbox)
            # Sheet one was regenerated with extra margins; restore the shared art scale.
            # No per-pose squash/stretch or interpolation.
            scale=1.35 if sheet_index==0 else 1.05
            sprite=crop.resize((round(crop.width*scale),round(crop.height*scale)),Image.Resampling.LANCZOS)
            # Place the genuinely articulated flight poses on a common animation stage.
            lift=0
            if 8<=index<=33:
                t=(index-8)/25
                lift=round(105*4*t*(1-t))
            canvas=Image.new('RGBA',(640,640),(255,255,255,0))
            x=(640-sprite.width)//2;y=580-lift-sprite.height
            assert x>=0 and y>=0 and x+sprite.width<=640,(index,bbox,sprite.size,x,y)
            canvas.alpha_composite(sprite,(x,y))
            file=out/'frames'/f'maria-celebrate-{index+1:02}.png'
            canvas.save(file);frames.append(canvas)
            records.append({'frame':index+1,'sheet':dest.name,'cell':[col,row],
                'source_bbox_in_column':bbox,'lift_px':lift,'sha256':hashlib.sha256(file.read_bytes()).hexdigest()})

assert len(set(r['sha256'] for r in records))==50
# The GIF uses a clean white matte; PNGs/atlas retain cutout alpha for the game.
rgb_frames=[]
for frame in frames:
    matte=Image.new('RGB',(640,640),'white');matte.paste(frame,mask=frame.getchannel('A'));rgb_frames.append(matte)
palette_sheet=Image.new('RGB',(640*10,640*5),'white')
for i,frame in enumerate(rgb_frames): palette_sheet.paste(frame,((i%10)*640,(i//10)*640))
palette=palette_sheet.quantize(colors=256)
indexed=[im.quantize(palette=palette,dither=Image.Dither.NONE) for im in rgb_frames]
durations=[60]*50;durations[0]=120;durations[-1]=120
gif=out/'Maria-Dynamic-50-Pose-Celebration.gif'
indexed[0].save(gif,save_all=True,append_images=indexed[1:],duration=durations,loop=0,disposal=2,optimize=False)
with Image.open(gif) as check:
    assert check.n_frames==50 and check.info['loop']==0
    total=0
    for i in range(50): check.seek(i);total+=check.info['duration']
    assert total==3120
palette_sheet.resize((1600,800),Image.Resampling.LANCZOS).save(out/'all-50-poses.png')
atlas=Image.new('RGBA',(3200,1600))
for i,frame in enumerate(frames): atlas.alpha_composite(frame.resize((320,320),Image.Resampling.LANCZOS),((i%10)*320,(i//10)*320))
atlas.save(out/'maria-celebration-atlas.png')
metadata={'generation':'Built-in ImageGen, five ten-pose sheets; every body pose separately generated within its sheet',
    'frame_count':50,'size':[640,640],'duration_ms':total,'durations_ms':durations,
    'gif_background':'white matte','png_and_atlas':'cutouts sliced from corrected white-background sheets',
    'atlas':{'columns':10,'rows':5,'cell_size':320},'frames':records}
(out/'animation.json').write_text(json.dumps(metadata,indent=2))
with zipfile.ZipFile(out/'Maria-Dynamic-50-Poses.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for file in sorted(out.rglob('*')):
        if file.is_file() and file.suffix!='.zip' and file.suffix!='.log': archive.write(file,file.relative_to(out))
print('VERIFIED: 50 distinct generated pose frames; 3120 ms infinite GIF; sheets, PNGs and atlas packaged')

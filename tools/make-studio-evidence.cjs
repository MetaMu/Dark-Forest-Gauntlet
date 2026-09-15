const fs=require('fs'),path=require('path'),crypto=require('crypto');
const sharp=require('C:/Users/rosec/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
(async()=>{
 const base=path.resolve(__dirname,'..'),dir=path.join(base,'artifacts/studio-vfx');
 const files=['01_ember.png','02_ironbark.png','03_spore.png','04_light.png'];
 const tiles=await Promise.all(files.map(file=>sharp(path.join(dir,file)).resize(640,360).toBuffer()));
 await sharp({create:{width:1280,height:720,channels:3,background:'#101c25'}})
  .composite(tiles.map((input,i)=>({input,left:(i%2)*640,top:Math.floor(i/2)*360})))
  .png().toFile(path.join(dir,'studio-vfx-preview.png'));
 const frames=[];
 for(let i=0;i<36;i++)frames.push(await sharp(path.join(dir,'frames',`cast_${String(i).padStart(3,'0')}.png`)).resize(768,432).removeAlpha().raw().toBuffer());
 await sharp(Buffer.concat(frames),{raw:{width:768,height:432*36,channels:3,pageHeight:432}})
  .gif({delay:Array.from({length:36},(_,i)=>i%3===2?90:80),loop:0,colours:192})
  .toFile(path.join(dir,'Studio-Powers-Preview.gif'));
 const tracked=['scripts/realm_vfx.gd','scripts/power_showcase.gd','tests/studio_vfx_regression.gd',...files.map(f=>'artifacts/studio-vfx/'+f),'artifacts/studio-vfx/05_all_four.png','artifacts/studio-vfx/06_dark_ground.png'];
 const roster=tracked.map(file=>({file,sha256:crypto.createHash('sha256').update(fs.readFileSync(path.join(base,file))).digest('hex')}));
 fs.writeFileSync(path.join(dir,'evidence-hashes.json'),JSON.stringify(roster,null,2));
 console.log('Created four-power comparison, motion preview and evidence hashes');
})();

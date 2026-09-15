const fs=require('fs'),path=require('path'),crypto=require('crypto');
const sharp=require(process.env.SHARP_MODULE||'C:/Users/rosec/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root=path.resolve(__dirname,'..'),prefix=process.argv[2]||'power-fx-v3',dir=path.join(root,'artifacts',prefix);
const hash=data=>crypto.createHash('sha256').update(data).digest('hex');
(async()=>{
 const vendor=path.join(root,'assets/vendor/power-fx');
 const receipt=JSON.parse(fs.readFileSync(path.join(vendor,'receipt.json')));
 for(const row of receipt.files){
  const data=fs.readFileSync(path.join(vendor,row.file)),meta=await sharp(data).metadata();
  if(hash(data)!==row.sha256||row.license!=='CC0-1.0'||!meta.hasAlpha||meta.width>512||meta.height>512)throw Error(`Invalid texture: ${row.file}`);
 }
 const titles=['Ember Hollow · Flame Dash','Ironbark · Piercing Volley','Spore Grove · Root Snare','Light Realm · Sanctuary'];
 const files=['01_ember','02_ironbark','03_spore','04_light'];
 const panels=[];
 for(let i=0;i<4;i++){
  const left=(i%2)*640,top=Math.floor(i/2)*398;
  panels.push({input:await sharp(path.join(dir,files[i]+'.png')).resize(640,360).png().toBuffer(),left,top:top+38});
  panels.push({input:Buffer.from(`<svg width="640" height="38"><text x="16" y="26" fill="#ede2be" font-family="Arial" font-size="19">${titles[i]}</text></svg>`),left,top});
 }
 await sharp({create:{width:1280,height:796,channels:3,background:'#141d1c'}}).composite(panels).png().toFile(path.join(dir,prefix+'-preview.png'));
 const frames=[];
 for(let i=0;i<36;i++)frames.push(await sharp(path.join(dir,`frames/cast_${String(i).padStart(3,'0')}.png`)).resize(960,540).removeAlpha().raw().toBuffer());
 await sharp(Buffer.concat(frames),{raw:{width:960,height:540*frames.length,channels:3,pageHeight:540}}).gif({delay:83,loop:0,colours:128,dither:.5}).toFile(path.join(dir,prefix+'-motion.gif'));
 const deliverables=[...files.map(f=>f+'.png'),'05_all_four.png','06_dark_ground.png',prefix+'-preview.png',prefix+'-motion.gif','timing.json'];
 const manifest=deliverables.map(file=>{const data=fs.readFileSync(path.join(dir,file));return{file,bytes:data.length,sha256:hash(data)};});
 fs.writeFileSync(path.join(dir,'review-manifest.json'),JSON.stringify({description:'Actual Godot gameplay renderer captures. Staged review targets and automatic four-player casts.',files:manifest},null,2)+'\n');
 console.log(`Verified ${receipt.files.length} CC0 textures; created four-power sheet, 36-frame motion preview and review manifest.`);
})().catch(e=>{console.error(e);process.exit(1)});

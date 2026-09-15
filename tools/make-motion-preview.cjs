const fs=require('fs'),path=require('path');
const sharp=require(process.env.SHARP_MODULE||'C:/Users/rosec/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
(async()=>{
 const dir=path.resolve(__dirname,'../artifacts/polish');
 const frames=[];
 for(let i=0;i<12;i++)frames.push(await sharp(path.join(dir,`walk_${String(i).padStart(2,'0')}.png`)).resize(768,432).removeAlpha().raw().toBuffer());
 await sharp(Buffer.concat(frames),{raw:{width:768,height:432*12,channels:3,pageHeight:432}}).gif({delay:100,loop:0,colours:128}).toFile(path.join(dir,'gnome-motion.gif'));
 console.log('Created 12-frame motion preview');
})();

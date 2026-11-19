const fs=require('fs'),path=require('path');
const sharp=require(process.env.SHARP_MODULE||'C:/Users/rosec/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
(async()=>{for(const name of ['spore','light']){
 const count=name==='spore'?70:50,delay=name==='spore'?67:33;
 const dir=path.resolve(__dirname,'../artifacts/'+name+'-upgrade');const frames=[];
 for(let i=0;i<count;i++)frames.push(await sharp(path.join(dir,'frames/'+name+'_'+String(i).padStart(3,'0')+'.png')).resize(960,540).removeAlpha().raw().toBuffer());
 await sharp(Buffer.concat(frames),{raw:{width:960,height:540*count,channels:3,pageHeight:540}}).gif({delay:frames.map((_,i)=>i===count-1?600:delay),loop:0,colours:192,dither:.4}).toFile(path.join(dir,name+'-motion.gif'));
 console.log('Created '+name+' real-time gameplay preview.');
}})().catch(e=>{console.error(e);process.exit(1)});

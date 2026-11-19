const path=require('path');
const sharp=require(process.env.SHARP_MODULE||'C:/Users/rosec/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
(async()=>{
 const dir=path.resolve(__dirname,'../artifacts/gnomish-ui');const panels=[];
 const files=['01-selection','04-pause','05-controls','07-victory'];
 const labels=['Choose your gnome','Parchment pause menu','Keyboard controls','Victory celebration'];
 for(let i=0;i<4;i++){
  const left=(i%2)*640,top=Math.floor(i/2)*398;
  panels.push({input:await sharp(path.join(dir,files[i]+'.png')).resize(640,360).png().toBuffer(),left,top:top+38});
  panels.push({input:Buffer.from('<svg width="640" height="38"><text x="16" y="26" fill="#ecdbb2" font-family="Georgia" font-size="20">'+labels[i]+'</text></svg>'),left,top});
 }
 await sharp({create:{width:1280,height:796,channels:3,background:'#16251e'}}).composite(panels).png().toFile(path.join(dir,'Gnomish-Menus-Preview.png'));
 console.log('Saved four-screen in-game menu review.');
})().catch(e=>{console.error(e);process.exit(1)});

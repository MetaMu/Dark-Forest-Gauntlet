const fs=require('fs'),path=require('path');
const sharp=require('C:/Users/rosec/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root=path.resolve(__dirname,'..','artifacts','power-design');
const shots=[
 ['01_ember_dash_burst_mid_power.png','EMBER HOLLOW — DASH BURST','#ff8248'],
 ['02_ironbark_piercing_volley_mid_power.png','IRONBARK — PIERCING VOLLEY','#78c99b'],
 ['03_spore_grove_root_snare_mid_power.png','SPORE GROVE — ROOT SNARE','#c18aea'],
 ['04_light_realm_sanctuary_mid_power.png','LIGHT REALM — SANCTUARY','#ffe18a']
];
const W=640,H=360,label=48,gap=12,canvasW=W*2+gap*3,canvasH=(H+label)*2+gap*3;
const escape=s=>s.replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]));
(async()=>{
 const composite=[];
 for(let i=0;i<shots.length;i++){
  const [file,title,color]=shots[i],x=gap+(i%2)*(W+gap),y=gap+Math.floor(i/2)*(H+label+gap);
  const image=await sharp(path.join(root,file)).resize(W,H,{fit:'fill'}).png().toBuffer();
  const svg=Buffer.from(`<svg width="${W}" height="${label}"><rect width="100%" height="100%" fill="#0a1014"/><rect width="7" height="100%" fill="${color}"/><text x="22" y="31" fill="${color}" font-family="Arial,sans-serif" font-weight="700" font-size="18">${escape(title)}</text></svg>`);
  composite.push({input:image,left:x,top:y},{input:svg,left:x,top:y+H});
 }
 await sharp({create:{width:canvasW,height:canvasH,channels:4,background:'#05090c'}}).composite(composite).png().toFile(path.join(root,'all_powers_mid_cast_preview.png'));
 const manifest={created:new Date().toISOString(),resolution:'1280x720 individual; 1316x852 preview',files:shots.map(s=>s[0]).concat('all_powers_mid_cast_preview.png')};
 fs.writeFileSync(path.join(root,'manifest.json'),JSON.stringify(manifest,null,2));
 console.log('POWER DESIGN SHEET COMPLETE');
})().catch(e=>{console.error(e);process.exit(1)});

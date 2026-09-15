const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const sharp = require(process.env.SHARP_MODULE || 'C:/Users/rosec/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root = path.resolve(__dirname, '..');
const out = path.join(root, 'assets/characters/gnomes/v1');
const source = path.join(out, 'sources');
const names = ['universal','ember_hollow','ironbark','spore_grove','light_realm'];
const views = ['front','side_right','back','three_quarter_right'];
const hash = b => crypto.createHash('sha256').update(b).digest('hex');
async function main() {
 const manifest = {version:1,frame_size:[512,512],pivot_pixels:[256,464],pivot_normalized:[0.5,0.90625],character_height:416,view_order:views,animation:'A-pose base frames only; no motion cycle',assets:[]};
 const preview = [];
 for (const [row,name] of names.entries()) {
  const file = path.join(source,name+'.png');
  const {data,info} = await sharp(file).removeAlpha().raw().toBuffer({resolveWithObject:true});
  const {width:w,height:h}=info, n=w*h;
  const bg=new Uint8Array(n), queue=new Int32Array(n); let head=0,tail=0;
  const eligible = p => {const i=p*3,r=data[i],g=data[i+1],b=data[i+2];return Math.min(r,g,b)>75 && Math.max(r,g,b)-Math.min(r,g,b)<28;};
  const add=p=>{if(!bg[p] && eligible(p)){bg[p]=1;queue[tail++]=p;}};
  for(let x=0;x<w;x++){add(x);add((h-1)*w+x);} for(let y=0;y<h;y++){add(y*w);add(y*w+w-1);}
  while(head<tail){const p=queue[head++],x=p%w;if(x)add(p-1);if(x<w-1)add(p+1);if(p>=w)add(p-w);if(p<n-w)add(p+w);}
  const seen=new Uint8Array(n), components=[];
  for(let p=0;p<n;p++) if(!bg[p]&&!seen[p]) {
   head=0;tail=0;queue[tail++]=p;seen[p]=1;const points=[];let x0=w,y0=h,x1=0,y1=0;
   while(head<tail){const q=queue[head++],x=q%w,y=Math.floor(q/w);points.push(q);x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);
    for(const k of [x?q-1:-1,x<w-1?q+1:-1,q>=w?q-w:-1,q<n-w?q+w:-1])if(k>=0&&!bg[k]&&!seen[k]){seen[k]=1;queue[tail++]=k;}
   } if(points.length>10000)components.push({points,x0,y0,x1,y1});
  }
  components.sort((a,b)=>a.x0-b.x0); if(components.length!==4)throw Error(name+': expected four silhouettes, got '+components.length);
  const frames=[];
  for(const [i,c] of components.entries()) {
   const cw=c.x1-c.x0+1,ch=c.y1-c.y0+1,rgba=Buffer.alloc(cw*ch*4);
   for(const p of c.points){const target=((Math.floor(p/w)-c.y0)*cw+p%w-c.x0)*4;data.copy(rgba,target,p*3,p*3+3);rgba[target+3]=255;}
   const fw=Math.round(cw*416/ch);if(fw>464)throw Error('Silhouette exceeds safe width');
   const sprite=await sharp(rgba,{raw:{width:cw,height:ch,channels:4}}).resize(fw,416).png().toBuffer();
   const frame=await sharp({create:{width:512,height:512,channels:4,background:'#00000000'}}).composite([{input:sprite,left:256-Math.floor(fw/2),top:48}]).png().toBuffer();
   const filename=`gnome_${name}_apose_${views[i]}_000.png`;fs.writeFileSync(path.join(out,filename),frame);frames.push(frame);
   const {data:check,info:ci}=await sharp(frame).raw().toBuffer({resolveWithObject:true});let transparent=0,opaque=0;
   for(let p=3;p<check.length;p+=4){if(check[p]===0)transparent++;if(check[p]===255)opaque++;}
   if(ci.channels!==4||transparent<512*48||opaque<10000)throw Error('Invalid alpha '+filename);
   manifest.assets.push({file:filename,sha256:hash(frame),view:views[i],character:name,source_bounds:[c.x0,c.y0,cw,ch],size:[512,512],transparent_pixels:transparent,opaque_pixels:opaque});
   preview.push({input:await sharp(frame).resize(256,256).toBuffer(),left:i*256,top:row*256});
  }
  await sharp({create:{width:2048,height:512,channels:4,background:'#00000000'}}).composite(frames.map((input,i)=>({input,left:i*512,top:0}))).png().toFile(path.join(out,`gnome_${name}_apose_sheet.png`));
 }
 fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
 await sharp({create:{width:1024,height:1280,channels:3,background:'#35434b'}}).composite(preview).png().toFile(path.join(out,'preview.png'));
 console.log('Validated 20 RGBA frames at 512x512; 5 strips at 2048x512.');
}
main().catch(e=>{console.error(e);process.exit(1);});

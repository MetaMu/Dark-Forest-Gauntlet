const fs=require('fs'),path=require('path'),crypto=require('crypto');
const root=path.resolve(__dirname,'..');
const digest=b=>crypto.createHash('sha256').update(b).digest('hex');
let glbs=0,maps=0;
const receipt=JSON.parse(fs.readFileSync(path.join(root,'assets/environment/moonlit-ruins/receipt.json')));
for(const item of receipt.files){
 const b=fs.readFileSync(path.join(root,item.file));
 if(digest(b)!==item.sha256||b.length!==item.bytes)throw Error('Hash mismatch '+item.file);
 if(b.toString('ascii',0,4)!=='glTF'||b.readUInt32LE(4)!==2||b.readUInt32LE(8)!==b.length)throw Error('Invalid GLB');
 const json=JSON.parse(b.toString('utf8',20,20+b.readUInt32LE(12)));
 const binaryStart=28+b.readUInt32LE(12);
 for(const image of json.images||[]){
  const view=json.bufferViews[image.bufferView];
  const start=binaryStart+(view.byteOffset||0);
  if(b.toString('ascii',start+1,start+4)==='PNG'&&(b.readUInt32BE(start+16)>1024||b.readUInt32BE(start+20)>1024))throw Error('Texture budget exceeded '+item.file);
 }
 if((json.buffers||[]).some(x=>x.uri)||(json.images||[]).some(x=>x.uri))throw Error('External GLB dependency '+item.file);
 if((json.extensionsRequired||[]).some(x=>/draco|meshopt/i.test(x)))throw Error('Unsupported compression');
 let triangles=0;
 for(const mesh of json.meshes||[])for(const p of mesh.primitives){
  if(p.mode!==undefined&&p.mode!==4)throw Error('Non-triangle primitive');
  triangles+=(p.indices!==undefined?json.accessors[p.indices].count:json.accessors[p.attributes.POSITION].count)/3;
 }
 if(triangles>60000)throw Error('Triangle budget exceeded');
 if(triangles!==item.triangles)throw Error('Triangle receipt mismatch '+item.file);
 glbs++;
}
const textures=JSON.parse(fs.readFileSync(path.join(root,'assets/vendor/polyhaven-forest/receipt.json')));
for(const item of textures.files){
 const b=fs.readFileSync(path.join(root,'assets/vendor/polyhaven-forest',item.file));
 if(digest(b)!==item.sha256||b.length!==item.bytes)throw Error('Texture hash mismatch');
 if(item.license!=='CC0-1.0')throw Error('Unreviewed license');
 maps++;
}
console.log(`ART VERIFIED: ${glbs} embedded GLBs, ${maps} licensed texture maps; hashes, topology, and dependencies passed.`);

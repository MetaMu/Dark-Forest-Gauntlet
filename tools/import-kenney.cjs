const fs=require('fs'),path=require('path'),crypto=require('crypto');
const root=path.resolve(__dirname,'..');
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const packs=[
 {id:'kenney-nature',folder:'nature',archive:'nature.zip',version:'2.1',url:'https://kenney.nl/assets/nature-kit',download:'https://kenney.nl/media/pages/assets/nature-kit/37ac38a37b-1677698939/kenney_nature-kit.zip',base:'Models/GLTF format',files:['tree_oak','tree_detailed_dark','tree_pineRoundC','tree_small','rock_largeA','rock_largeC','rock_tallA','stone_smallFlatA','stump_roundDetailed','stump_old','log','log_large','grass_large','grass_leafs','plant_bush','mushroom_redGroup','mushroom_tanGroup'].map(n=>n+'.glb')},
 {id:'kenney-impact',folder:'impact',archive:'impact.zip',version:'1.0',url:'https://kenney.nl/assets/impact-sounds',download:'https://kenney.nl/media/pages/assets/impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip',base:'Audio',files:['footstep_grass_000.ogg','footstep_grass_001.ogg','impactWood_heavy_000.ogg','impactWood_light_000.ogg','impactMetal_light_000.ogg']}
];
for(const p of packs){
 const src=path.join(root,'artifacts/vendor-staging',p.folder),dest=path.join(root,'assets/vendor',p.id);
 const license=fs.readFileSync(path.join(src,'License.txt'));
 if(!license.toString().includes('CC0'))throw Error('License gate failed');
 const roster=[];
 for(const name of p.files){
  const bytes=fs.readFileSync(path.join(src,p.base,name));
  let inspection={};
  if(name.endsWith('.glb')){
   if(bytes.toString('ascii',0,4)!=='glTF'||bytes.readUInt32LE(4)!==2||bytes.readUInt32LE(8)!==bytes.length)throw Error('GLB header invalid');
   const size=bytes.readUInt32LE(12),doc=JSON.parse(bytes.toString('utf8',20,20+size));
   if([...(doc.buffers||[]),...(doc.images||[])].some(v=>v.uri&&!v.uri.startsWith('data:')))throw Error('External dependency');
   const triangles=(doc.meshes||[]).flatMap(m=>m.primitives).reduce((a,v)=>a+(v.indices===undefined?doc.accessors[v.attributes.POSITION].count:doc.accessors[v.indices].count)/3,0);
   if(triangles>15000)throw Error('Triangle budget exceeded');
   inspection={triangles,meshes:doc.meshes.length,embeddedDependencies:true};
  }else if(bytes.toString('ascii',0,4)!=='OggS')throw Error('Invalid Ogg');
  roster.push({file:name,sha256:hash(bytes),bytes:bytes.length,...inspection});
 }
 fs.mkdirSync(dest,{recursive:true});
 for(const entry of roster){
  const from=path.join(src,p.base,entry.file),to=path.join(dest,entry.file);
  if(fs.existsSync(to)&&hash(fs.readFileSync(to))!==entry.sha256)throw Error('Destination collision');
  fs.copyFileSync(from,to);
  if(hash(fs.readFileSync(to))!==entry.sha256)throw Error('Copy verification failed');
 }
 fs.writeFileSync(path.join(dest,'LICENSE.txt'),license);
 fs.writeFileSync(path.join(dest,'receipt.json'),JSON.stringify({id:p.id,version:p.version,source:p.url,download:p.download,license:'CC0-1.0',license_sha256:hash(license),archive_sha256:hash(fs.readFileSync(path.join(root,'artifacts/vendor-staging',p.archive))),acquired:'2026-09-09',method:'User-authorized local verification; game-dev CLI unavailable',validation:'Header, embedded dependency, triangle budget and copied SHA-256 checks. Engine validation recorded separately.',files:roster},null,2));
 console.log(p.id+': verified '+roster.length+' files');
}

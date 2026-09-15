// Original synthesized ambient bed; deterministic, seamless 16-second PCM loop.
const fs=require('fs'),path=require('path');
const rate=22050,seconds=16,count=rate*seconds,b=Buffer.alloc(44+count*2);
b.write('RIFF');b.writeUInt32LE(b.length-8,4);b.write('WAVEfmt ',8);b.writeUInt32LE(16,16);b.writeUInt16LE(1,20);b.writeUInt16LE(1,22);b.writeUInt32LE(rate,24);b.writeUInt32LE(rate*2,28);b.writeUInt16LE(2,32);b.writeUInt16LE(16,34);b.write('data',36);b.writeUInt32LE(count*2,40);
for(let i=0;i<count;i++){const t=i/rate;let v=0;for(const [hz,amp] of [[110,.1],[164.8125,.055],[220,.03],[261.625,.018]])v+=Math.sin(2*Math.PI*hz*t)*amp*(.7+.3*Math.sin(2*Math.PI*t/16));
 // Gentle periodic air and distant chirps, no external samples.
 for(let k=0;k<8;k++){const d=t-(k*2+.7);if(d>0&&d<.3)v+=Math.sin(2*Math.PI*(1300*d+120*d*d))*Math.sin(Math.PI*d/.3)**2*.018;}
 b.writeInt16LE(Math.round(v*20000),44+i*2);}
const dir=path.resolve(__dirname,'../assets/audio');fs.mkdirSync(dir,{recursive:true});fs.writeFileSync(path.join(dir,'forest_ambience.wav'),b);

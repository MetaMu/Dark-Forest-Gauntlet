const fs = require('fs');
const path = require('path');
const sharp = require(process.env.SHARP_MODULE || 'C:/Users/rosec/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const dir = path.resolve(__dirname, '../artifacts/ironbark-upgrade');
(async () => {
  const frames = [];
  for (let i = 0; i < 50; i++) {
    frames.push(await sharp(path.join(dir, `frames/ironbark_${String(i).padStart(3, '0')}.png`)).resize(960, 540).removeAlpha().raw().toBuffer());
  }
  await sharp(Buffer.concat(frames), {raw: {width: 960, height: 540 * frames.length, channels: 3, pageHeight: 540}})
    .gif({delay: frames.map((_, i) => i === 49 ? 600 : 33), loop: 0, colours: 192, dither: .4})
    .toFile(path.join(dir, 'ironbark-motion.gif'));
  console.log('Created real-time Ironbark gameplay preview.');
})().catch(error => { console.error(error); process.exit(1); });

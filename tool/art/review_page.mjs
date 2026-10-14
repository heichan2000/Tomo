#!/usr/bin/env node
// Builds the art review pages from the Dart source (ADR-0020).
//
//   node tool/art/review_page.mjs [geode|joe|lily ...] [--out page.html]
//
// Reads packages/tomo_core/lib/art/: the pets in pets/<species>.dart (all three
// unless named), and the icons, sparkle and Tomo egg. Checks every grid and
// movement, computes each drawing's fingerprint and writes two self-contained
// HTML pages:
//
// - pets.html: a Pet switch, then each drawing on the light and black grounds,
//   at phone size and zoomed, its parts, faces, every shared movement, the
//   evolution flicker, the egg's crack steps and hatch, and the checks;
// - kit.html, beside it: the 20 icons in their colours and in every accent, the
//   sparkle's frames and plays in every pet's colours, and the Tomo egg.
//
// The user approves drawings on these pages, never on a hand-made one. Exits 1
// if a grid is broken; a failed movement check is shown, not fatal.

import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { checks, drawings, kitChecks, kitDrawings, readKit, readSpecies } from './pixel_art.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = join(HERE, '..', '..');
const ART = join(ROOT, 'packages', 'tomo_core', 'lib', 'art');
const ALL = ['geode', 'joe', 'lily'];

const args = process.argv.slice(2);
const outAt = args.indexOf('--out');
const out = outAt >= 0 ? args.splice(outAt, 2)[1] : join(ROOT, 'build', 'art-review', 'pets.html');
const kitOut = join(dirname(out), 'kit.html');
const names = args.length ? args : ALL;
for (const n of names) if (!ALL.includes(n)) { console.error(`usage: review_page.mjs [${ALL.join('|')} ...] [--out page.html]`); process.exit(2); }

const built = new Date().toISOString().slice(0, 16).replace('T', ' ');
const page = (template, data, extra = s => s) => extra(readFileSync(join(HERE, template), 'utf8')
  .replace('/*{{DATA}}*/null', () => JSON.stringify(data)));
const write = (path, html) => { mkdirSync(dirname(path), { recursive: true }); writeFileSync(path, html); };

let broken = false;
const species = names.map(n => {
  const sp = readSpecies(join(ART, 'pets', `${n}.dart`));
  const ch = checks(sp);
  broken ||= !ch[1][0];   // the grids themselves
  return { ...sp, drawings: drawings(sp), checks: ch };
});
const pose = readFileSync(join(HERE, 'pose.mjs'), 'utf8').replace(/^export /gm, '');
write(out, page('review_page.template.html', { built, species }, s => s.replace('/*{{POSE}}*/', () => pose)));

const kit = readKit(ART);
const kitCh = kitChecks(kit);
broken ||= kitCh.some(([ok]) => !ok);
const kitDr = kitDrawings(kit);
write(kitOut, page('kit_page.template.html', { built, kit, drawings: kitDr, checks: kitCh }));

for (const sp of species) {
  console.log(`== ${sp.name}`);
  for (const [ok, text] of sp.checks) console.log(`${ok ? 'ok   ' : 'LOOK '} ${text}`);
  for (const d of sp.drawings) console.log(`${d.status.padEnd(9)}${d.id.padEnd(15)}${d.fingerprint}`);
}
console.log('== Icons, sparkle and Tomo egg');
for (const [ok, text] of kitCh) console.log(`${ok ? 'ok   ' : 'LOOK '} ${text}`);
for (const d of kitDr) console.log(`${d.status.padEnd(9)}${d.id.padEnd(15)}${d.fingerprint}`);
console.log(`wrote ${out}\nwrote ${kitOut}`);
process.exit(broken ? 1 : 0);

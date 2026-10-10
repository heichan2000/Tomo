#!/usr/bin/env node
// Builds the pet art review page from the Dart source (ADR-0020).
//
//   node tool/art/review_page.mjs [geode|joe|lily ...] [--out page.html]
//
// Reads lib/art/pets/<species>.dart (all three unless named), checks every
// grid and movement, computes each drawing's fingerprint and writes one
// self-contained HTML page: a Pet switch, then each drawing on the light and
// black grounds, at phone size and zoomed, its parts, faces, every shared
// movement, the evolution flicker, the egg's crack steps and hatch, and the
// checks. The user approves drawings on this page, never on a hand-made one.
// Exits 1 if a grid is broken; a failed movement check is shown, not fatal.

import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { checks, drawings, readSpecies } from './pixel_art.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = join(HERE, '..', '..');
const ALL = ['geode', 'joe', 'lily'];

const args = process.argv.slice(2);
const outAt = args.indexOf('--out');
const out = outAt >= 0 ? args.splice(outAt, 2)[1] : join(ROOT, 'build', 'art-review', 'pets.html');
const names = args.length ? args : ALL;
for (const n of names) if (!ALL.includes(n)) { console.error(`usage: review_page.mjs [${ALL.join('|')} ...] [--out page.html]`); process.exit(2); }

let broken = false;
const species = names.map(n => {
  const sp = readSpecies(join(ROOT, 'lib', 'art', 'pets', `${n}.dart`));
  const ch = checks(sp);
  broken ||= !ch[1][0];   // the grids themselves
  return { ...sp, drawings: drawings(sp), checks: ch };
});

const pose = readFileSync(join(HERE, 'pose.mjs'), 'utf8').replace(/^export /gm, '');
const data = { built: new Date().toISOString().slice(0, 16).replace('T', ' '), species };
const html = readFileSync(join(HERE, 'review_page.template.html'), 'utf8')
  .replace('/*{{DATA}}*/null', () => JSON.stringify(data))
  .replace('/*{{POSE}}*/', () => pose);
mkdirSync(dirname(out), { recursive: true });
writeFileSync(out, html);

for (const sp of species) {
  console.log(`== ${sp.name}`);
  for (const [ok, text] of sp.checks) console.log(`${ok ? 'ok   ' : 'LOOK '} ${text}`);
  for (const d of sp.drawings) console.log(`${d.status.padEnd(9)}${d.id.padEnd(15)}${d.fingerprint}`);
}
console.log(`wrote ${out}`);
process.exit(broken ? 1 : 0);

// Reads a species' art from its Dart file, fingerprints each drawing and checks
// it (ADR-0020). The Dart side of the model is lib/art/pixel_art.dart; the
// fingerprint rule is written out in its library doc, and this computes it.

import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { N, PARTS, SHAPES, compose, eyeLayer, gaps, newHoles, slivers } from './pose.mjs';

// ---------- the Dart subset the species files are written in ----------
// Constructor calls with named or positional arguments, lists, maps, sets,
// records, strings (raw triple-quoted for grids), integers and Enum.value names.

const TOKEN = /\s+|\/\/[^\n]*|(?<raw>r'''[\s\S]*?''')|(?<str>'[^'\n]*')|(?<num>0x[0-9A-Fa-f]+|-?\d+)|(?<name>[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?)|(?<p>[\[\]{}(),:;=])/y;

function tokens(src) {
  const out = [];
  TOKEN.lastIndex = 0;
  while (TOKEN.lastIndex < src.length) {
    const at = TOKEN.lastIndex, m = TOKEN.exec(src);
    if (!m) throw new SyntaxError(`unexpected ${JSON.stringify(src.slice(at, at + 20))}`);
    const kind = Object.keys(m.groups).find(k => m.groups[k] !== undefined);
    if (kind) out.push([kind, m.groups[kind]]);
  }
  return out;
}

class Call { constructor(name, args, named) { Object.assign(this, { name, args, named }); } }

function parse(toks) {
  let i = 0;
  const peek = (k = 0) => toks[i + k] ?? [null, null];
  const take = want => {
    const t = toks[i++];
    if (want && t[1] !== want) throw new SyntaxError(`expected ${want}, got ${t[1]}`);
    return t;
  };
  const isNamedArg = () => peek()[0] === 'name' && peek(1)[1] === ':';
  function seq(open, close, item) {
    take(open);
    const out = [];
    while (peek()[1] !== close) { out.push(item()); if (peek()[1] === ',') take(); }
    take(close);
    return out;
  }
  function value() {
    const [kind, text] = peek();
    if (kind === 'raw') { take(); return { grid: text.slice(4, -3) }; }
    if (kind === 'str') { take(); return text.slice(1, -1); }
    if (kind === 'num') { take(); return Number(text); }
    if (text === '[') return seq('[', ']', value);
    if (text === '{') {
      // A map if its first entry has a key, otherwise a set.
      take('{');
      if (peek()[1] === '}') { take(); return new Map(); }
      const first = value();
      if (peek()[1] === ':') {
        const m = new Map();
        take(':'); m.set(first, value());
        while (peek()[1] === ',') { take(); if (peek()[1] === '}') break; const k = value(); take(':'); m.set(k, value()); }
        take('}');
        return m;
      }
      const s = new Set([first]);
      while (peek()[1] === ',') { take(); if (peek()[1] === '}') break; s.add(value()); }
      take('}');
      return s;
    }
    if (text === '(') {
      // A record: (x: 1, y: 2) or (1, 2).
      const rec = {}, pos = [];
      take('(');
      while (peek()[1] !== ')') {
        if (isNamedArg()) { const k = take()[1]; take(':'); rec[k] = value(); } else pos.push(value());
        if (peek()[1] === ',') take();
      }
      take(')');
      return pos.length ? pos : rec;
    }
    if (kind === 'name') {
      take();
      if (peek()[1] !== '(') return text;
      const args = [], named = {};
      take('(');
      while (peek()[1] !== ')') {
        if (isNamedArg()) { const k = take()[1]; take(':'); named[k] = value(); } else args.push(value());
        if (peek()[1] === ',') take();
      }
      take(')');
      return new Call(text, args, named);
    }
    throw new SyntaxError(`unexpected ${text}`);
  }
  return value();
}

const rowsOf = g => {
  const rows = g.grid.split('\n');
  if (rows[0] === '') rows.shift();
  if (rows.at(-1) === '') rows.pop();
  return rows;
};
const partName = v => v.replace(/^Part\./, '');
const markOf = c => c.name === 'Approved' ? { fingerprint: c.named.fingerprint, approvedIn: c.named.approvedIn } : null;

/// The `const <id> = SpeciesArt(...)` in a species file, as plain data.
export function readSpecies(path) {
  const src = readFileSync(path, 'utf8');
  const m = /\bconst\s+(\w+)\s*=\s*SpeciesArt\s*\(/.exec(src);
  if (!m) throw new SyntaxError(`${path}: no \`const x = SpeciesArt(\``);
  const c = parse(tokens(src.slice(m.index + m[0].length - 'SpeciesArt('.length))).named;
  const set = v => [...(v ?? [])].map(partName);
  const colours = {};
  for (const [k, v] of c.colours) colours[k] = '#' + (v & 0xffffff).toString(16).padStart(6, '0');
  const egg = c.egg.named;
  return {
    id: m[1], name: c.name, colours,
    paintOrder: c.paintOrder.map(partName),
    ridesWithHead: set(c.ridesWithHead), leansWhole: set(c.leansWhole),
    twitches: set(c.twitches), liftsOnJump: set(c.liftsOnJump),
    egg: { mark: markOf(egg.mark), whole: rowsOf(egg.whole), cracks: egg.cracks.map(rowsOf), stays: [...(egg.staysAtHatch ?? [])] },
    stages: c.stages.map(s => ({
      mark: markOf(s.named.mark),
      eyes: s.named.eyes.map(e => [e.x, e.y]),
      lean: s.named.leanStep,
      breath: s.named.breathRow ?? null,
      parts: Object.fromEntries([...s.named.parts].map(([k, v]) => [partName(k), rowsOf(v)])),
    })),
    eyeSheet: {
      mark: markOf(c.eyeSheet.named.mark),
      faces: Object.fromEntries([...c.eyeSheet.named.faces].map(([k, e]) => {
        const [off, g] = e.args;
        return [k.replace(/^EyeShape\./, ''), { dx: off.x, dy: off.y, rows: rowsOf(g) }];
      })),
    },
  };
}

// ---------- fingerprints ----------

function colourLines(sp, grids) {
  const used = new Set();
  for (const g of grids) for (const r of g) for (const c of r) if (c !== '.') used.add(c);
  return [...used].sort().map(c => {
    if (!sp.colours[c]) throw new Error(`${sp.id}: '${c}' is not in the colour key`);
    return `colour ${c} ${sp.colours[c]}`;
  });
}
const list = parts => parts.length ? parts.join(' ') : '-';
const inOrder = parts => PARTS.filter(p => parts.includes(p));
const digest = lines => createHash('sha256').update(lines.join('\n'), 'utf8').digest('hex').slice(0, 16);

export function stageText(sp, i) {
  const st = sp.stages[i];
  const grids = PARTS.map(p => st.parts[p]);
  const lines = ['tomo-art 1', `drawing ${sp.id}.stage${i + 1}`, ...colourLines(sp, grids),
    `order ${list(sp.paintOrder)}`, `rides ${list(inOrder(sp.ridesWithHead))}`, `leans-whole ${list(inOrder(sp.leansWhole))}`,
    `twitches ${list(inOrder(sp.twitches))}`, `lifts-on-jump ${list(inOrder(sp.liftsOnJump))}`,
    ...st.eyes.map(([x, y]) => `eye ${x} ${y}`), `lean ${st.lean}`, `breath ${st.breath ?? '-'}`];
  PARTS.forEach((p, k) => lines.push(`grid ${p}`, ...grids[k]));
  return lines;
}
export function eggText(sp) {
  const e = sp.egg, grids = [e.whole, ...e.cracks];
  const lines = ['tomo-art 1', `drawing ${sp.id}.egg`, ...colourLines(sp, grids), `stays ${e.stays.length ? [...e.stays].sort().join('') : '-'}`];
  lines.push('grid whole', ...e.whole);
  e.cracks.forEach((g, k) => lines.push(`grid crack${k + 1}`, ...g));
  return lines;
}
export function eyesText(sp) {
  const f = sp.eyeSheet.faces;
  const lines = ['tomo-art 1', `drawing ${sp.id}.eyes`, ...colourLines(sp, SHAPES.map(s => f[s].rows))];
  for (const s of SHAPES) lines.push(`grid ${s} ${f[s].dx} ${f[s].dy}`, ...f[s].rows);
  return lines;
}

/// Every drawing of a species, with its fingerprint and whether it is a draft,
/// approved, or changed since it was approved.
export function drawings(sp) {
  const one = (id, label, mark, lines) => {
    const fingerprint = digest(lines);
    return { id, label, mark, fingerprint, status: !mark ? 'draft' : mark.fingerprint === fingerprint ? 'approved' : 'changed' };
  };
  return [
    one(`${sp.id}.egg`, 'Egg', sp.egg.mark, eggText(sp)),
    ...sp.stages.map((st, i) => one(`${sp.id}.stage${i + 1}`, `Stage ${i + 1}`, st.mark, stageText(sp, i))),
    one(`${sp.id}.eyes`, 'Eye sheet', sp.eyeSheet.mark, eyesText(sp)),
  ];
}

// ---------- checks ----------

// Every movement the app makes from a stage's parts, as a pose.
export const MOVES = [
  ['Breath', { drop: 1 }],
  ['Drowsy, sunk two', { face: 'drowsy', drop: 2 }],
  ['Lean left, first step', { lean: -1 }],
  ['Thinking, the full lean left', { lean: -2, edx: -1 }],
  ['Lean right, first step', { lean: 1, face: 'puzzled' }],
  ['Puzzled, the full lean right', { lean: 2, face: 'puzzled' }],
  ['Lean left while breathing', { lean: -1, drop: 1 }],
  ['Thinking while breathing', { lean: -2, edx: -1, drop: 1 }],
  ['Lean right while breathing', { lean: 1, face: 'puzzled', drop: 1 }],
  ['Puzzled while breathing', { lean: 2, face: 'puzzled', drop: 1 }],
  ['Twitch', { twitch: 1 }],
  ['Twitch while breathing', { twitch: 1, drop: 1 }],
  ['Top of the jump', { lift: 3, extra: 1 }],
  ['Glance left', { edx: -1 }],
  ['Glance right', { edx: 1 }],
  ['Look up', { edy: -1 }],
  ['Pleased', { face: 'pleased' }],
  ['Blink', { face: 'blink' }],
];

/// [ok, text] lines for the page and the console.
export function checks(sp) {
  const out = [];
  const add = (ok, good, bad) => out.push([ok, ok ? good : bad]);
  const keys = Object.keys(sp.colours);
  add(keys.length <= 7, `${keys.length} colours in the key, at most seven.`, `${keys.length} colours in the key; a pet has at most seven.`);

  const bad = [];
  const grids = [['egg whole', sp.egg.whole], ...sp.egg.cracks.map((g, k) => [`egg crack ${k + 1}`, g])];
  sp.stages.forEach((st, i) => PARTS.forEach(p => st.parts[p] ? grids.push([`stage ${i + 1} ${p}`, st.parts[p]]) : bad.push(`stage ${i + 1} has no ${p}`)));
  for (const [name, g] of grids) {
    if (g.length !== N || g.some(r => r.length !== N)) bad.push(`${name} is not ${N}×${N}`);
    const stray = new Set([...g.join('')].filter(c => c !== '.' && !sp.colours[c]));
    if (stray.size) bad.push(`${name} uses ${[...stray].join('')}, not in the key`);
  }
  for (const s of SHAPES) {
    const f = sp.eyeSheet.faces[s];
    if (!f) { bad.push(`the eye sheet has no ${s}`); continue; }
    const stray = new Set([...f.rows.join('')].filter(c => c !== '.' && !sp.colours[c]));
    if (stray.size) bad.push(`eye ${s} uses ${[...stray].join('')}, not in the key`);
  }
  add(!bad.length, 'Every grid is 48×48 and uses only the key; the eye sheet has every face.', bad.join('; ') + '.');
  if (bad.length) return out;   // the rest can't run on broken grids

  const bottoms = [...sp.stages.map((_, i) => compose(sp, i).g), sp.egg.whole].map(g => Math.max(...g.map((r, y) => r.replace(/\./g, '') ? y : -1)));
  add(bottoms.every(b => b === N - 2), `Every stage and the egg stand on row ${N - 2}.`, `Bottom rows differ: ${bottoms.join(', ')} (stages, then the egg).`);

  const eyesOff = [], leanLow = [];
  sp.stages.forEach((st, i) => {
    if (eyeLayer(sp, st, 'resting', 0, 0).join('') !== st.parts.eyes.join('')) eyesOff.push(i + 1);
    const top = Math.min(...st.eyes.map(([, y]) => y + sp.eyeSheet.faces.resting.dy));
    if (!(st.lean <= top - 1)) leanLow.push(i + 1);
  });
  add(!eyesOff.length, "Every stage's eyes part is the eye sheet's resting eyes at its eye spots.", `The eyes part differs from the resting eyes at stage ${eyesOff.join(', ')}.`);
  add(!leanLow.length, 'Every lean step is above the eyes.', `The lean step is not above the eyes at stage ${leanLow.join(', ')}.`);

  const outline = g => g.map(r => r.replace(/[^.]/g, '#')).join('');
  const offShell = sp.egg.cracks.map((g, k) => outline(g) !== outline(sp.egg.whole) ? k + 1 : 0).filter(Boolean);
  add(!offShell.length, 'Every crack picture keeps the whole egg\'s outline.', `Crack ${offShell.join(', ')} changes the egg's outline.`);

  const holey = [], gappy = [];
  sp.stages.forEach((_, i) => {
    for (const [name, pose] of MOVES) {
      const h = newHoles(sp, i, pose);
      if (h.length) holey.push(`stage ${i + 1}, ${name}: ${h.map(([x, y]) => `(${x},${y})`).join(' ')}`);
      const gp = gaps(sp, i, pose);
      if (gp.length) gappy.push(`stage ${i + 1}, ${name}: ${gp.map(([x, y]) => `(${x},${y})`).join(' ')}`);
    }
  });
  add(!holey.length, 'No movement opens a hole, at any stage.', 'Holes: ' + holey.join('; ') + '.');
  add(!gappy.length, 'No movement opens a gap between parts, at any stage.', 'Gaps: ' + gappy.join('; ') + '.');

  // Eye room (#31): glancing and looking up must land on the head, in view.
  const crowded = [];
  sp.stages.forEach((st, i) => {
    const top = Array.from({ length: N }, () => Array(N).fill(null));
    for (const k of sp.paintOrder) if (k !== 'eyes') st.parts[k].forEach((r, y) => [...r].forEach((c, x) => { if (c !== '.') top[y][x] = k; }));
    for (const [name, pose] of [['glance left', { edx: -1 }], ['glance right', { edx: 1 }], ['look up', { edy: -1 }]]) {
      const moved = eyeLayer(sp, st, 'resting', pose.edx ?? 0, pose.edy ?? 0), g = compose(sp, i, pose).g;
      const under = new Set(), hidden = [];
      moved.forEach((r, y) => [...r].forEach((c, x) => {
        if (c === '.') return;
        under.add(top[y][x] ?? 'nothing');
        if (g[y][x] !== c) hidden.push([x, y]);
      }));
      under.delete('head');
      if (under.size || hidden.length) crowded.push(`stage ${i + 1}, ${name}: ` + [under.size ? `lands on the ${[...under].join(' and ')}` : '', hidden.length ? `${hidden.length} eye px hidden` : ''].filter(Boolean).join(', '));
    }
  });
  add(!crowded.length, 'The eyes have a pixel of room to glance and look up, at every stage.', 'Eye room: ' + crowded.join('; ') + '.');

  const sl = slivers(sp);
  add(!sl.length, 'The hatch\'s seven pieces leave no slivers.', 'Hatch slivers: ' + sl.map(s => `piece ${s.piece}, ${s.px.length} px at ${s.px.map(([x, y]) => `(${x},${y})`).join(' ')}`).join('; ') + '.');
  return out;
}

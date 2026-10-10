// Putting a pet stage together in a pose, the way the app slides its parts
// (ADR-0018). The review page generator checks every movement with it, and the
// page itself plays the movements with the same code: review_page.mjs inlines
// this file into the page, so it must stay plain functions with no imports.

export const N = 48;
export const PARTS = ['body', 'head', 'eyes', 'limbA', 'limbB', 'accent'];
export const SHAPES = ['resting', 'blink', 'pleased', 'drowsy', 'puzzled'];

export const blank = () => Array.from({ length: N }, () => Array(N).fill('.'));

// The eyes layer: the face's sheet drawing at each of the stage's eye spots.
export function eyeLayer(sp, st, face, edx, edy) {
  const g = blank();
  const { dx, dy, rows } = sp.eyeSheet.faces[face];
  for (const [ex, ey] of st.eyes) rows.forEach((r, j) => [...r].forEach((c, i) => {
    const x = ex + dx + i + edx, y = ey + dy + j + edy;
    if (c !== '.' && x >= 0 && y >= 0 && x < N && y < N) g[y][x] = c;
  }));
  return g.map(r => r.join(''));
}

// A pose: { face, edx, edy, lean, drop, lift, extra, twitch, wiggle }, all
// whole pixels and all optional.
//   face    eye sheet shape (default resting); edx/edy move the eyes
//   lean    -2..2: left/right, one step or the full lean (Thinking, Puzzled)
//   drop    the breath sinking (1), Drowsy (2), the head landing late (1)
//   lift    the whole pet up (hop, jump)
//   extra   the species' liftsOnJump parts up one more, at the top of the jump
//   twitch  the species' twitching part up
//   wiggle  the whole pet sideways
// Returns { g, own }: rows of colour-key characters, and for every pixel the
// offset that put it there, so a check can tell parts that moved differently.
export function compose(sp, si, pose = {}) {
  const st = sp.stages[si];
  const p = { face: 'resting', edx: 0, edy: 0, lean: 0, drop: 0, lift: 0, extra: 0, twitch: 0, wiggle: 0 };
  for (const k in pose) if (pose[k] !== undefined) p[k] = pose[k];
  const g = blank(), own = Array.from({ length: N }, () => Array(N).fill(null));
  const d = Math.sign(p.lean), full = Math.abs(p.lean) === 2;
  for (const part of sp.paintOrder) {
    const rows = part === 'eyes' ? eyeLayer(sp, st, p.face, p.edx, p.edy) : st.parts[part];
    const rides = sp.ridesWithHead.includes(part);
    // Breathing sinks what rides with the head, and every row above the breath
    // row. Within a part, the rows that sink land on top of the rows below them.
    const sinks = y => rides || (st.breath != null && y < st.breath);
    for (const sinking of [false, true]) for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) {
      const c = rows[y][x];
      if (c === '.' || sinks(y) !== sinking) continue;
      let dx = p.wiggle, dy = -p.lift;
      if (sinking) dy += p.drop;
      if (sp.twitches.includes(part)) dy -= p.twitch;
      if (sp.liftsOnJump.includes(part)) dy -= p.extra;
      // Leaning slides what rides with the head: above the lean step two pixels, the rest one.
      if (d && rides) dx += d * (full && (sp.leansWhole.includes(part) || y < st.lean) ? 2 : 1);
      const X = x + dx, Y = y + dy;
      if (X < 0 || Y < 0 || X >= N || Y >= N) continue;
      g[Y][X] = c;
      own[Y][X] = dx + ',' + dy;
    }
  }
  return { g: g.map(r => r.join('')), own };
}

// Clear pixels the outside can't reach: holes inside the pet.
export function holes(g) {
  const seen = new Set(), stack = [];
  for (let i = 0; i < N; i++) stack.push([i, 0], [i, N - 1], [0, i], [N - 1, i]);
  while (stack.length) {
    const [x, y] = stack.pop();
    if (x < 0 || y < 0 || x >= N || y >= N || seen.has(y * N + x) || g[y][x] !== '.') continue;
    seen.add(y * N + x);
    stack.push([x + 1, y], [x - 1, y], [x, y + 1], [x, y - 1]);
  }
  const out = [];
  for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) if (g[y][x] === '.' && !seen.has(y * N + x)) out.push([x, y]);
  return out;
}

// Holes the pose opens: clear pixels walled in by the pet that it covered when
// still (moved only as a whole), and not just a clear bit of a part that moved
// as one, like the open work in Geode's crown sinking with it.
export function newHoles(sp, si, pose) {
  const rest = compose(sp, si, { face: pose.face, lift: pose.lift, wiggle: pose.wiggle }).g;
  const { g, own } = compose(sp, si, pose);
  return holes(g).filter(([x, y]) => {
    if (rest[y][x] === '.') return false;
    const moves = new Set([[1, 0], [-1, 0], [0, 1], [0, -1]].map(([dx, dy]) => own[y + dy]?.[x + dx]).filter(Boolean));
    if (moves.size !== 1) return true;
    const [ox, oy] = [...moves][0].split(',').map(Number);
    const base = compose(sp, si, { face: pose.face }).g;   // rest before the whole-pet lift and wiggle
    return base[y - oy]?.[x - ox] !== '.';
  });
}

// Gaps: pixels filled when the pet is still (moved only as a whole) that are
// empty in the pose, with filled neighbours on both sides that moved
// differently. A pose's lift, wiggle and face don't open gaps by themselves.
// A lean or twitch can play mid-breath; then the pixel must also be filled in
// the breath alone, since what the breath opens is judged on its own.
export function gaps(sp, si, pose) {
  const rest = compose(sp, si, { face: pose.face, lift: pose.lift, wiggle: pose.wiggle }).g;
  const onBreath = pose.drop && (pose.lean || pose.twitch || pose.extra);
  const breath = onBreath ? compose(sp, si, { face: pose.face, lift: pose.lift, wiggle: pose.wiggle, drop: pose.drop }).g : rest;
  const { g, own } = compose(sp, si, pose);
  const out = [];
  for (let y = 1; y < N - 1; y++) for (let x = 1; x < N - 1; x++) {
    if (g[y][x] !== '.' || rest[y][x] === '.' || breath[y][x] === '.') continue;
    for (const [dy, dx] of [[1, 0], [0, 1]]) {
      const a = g[y + dy][x + dx], b = g[y - dy][x - dx];
      if (a !== '.' && b !== '.' && own[y + dy][x + dx] !== own[y - dy][x - dx]) { out.push([x, y]); break; }
    }
  }
  return out;
}

// Pixels a part has that nobody sees while the pet is still: the ones painted
// in behind a moving part.
export function hiddenPixels(sp, si) {
  const st = sp.stages[si], out = [];
  const layers = sp.paintOrder.map(k => k === 'eyes' ? eyeLayer(sp, st, 'resting', 0, 0) : st.parts[k]);
  layers.forEach((rows, i) => {
    for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) {
      if (rows[y][x] === '.') continue;
      if (layers.slice(i + 1).some(r => r[y][x] !== '.')) out.push([x, y]);
    }
  });
  return out;
}

// The egg's seven pieces at the hatch: the last crack picture cut by angle
// around the middle of the egg, starting straight up and going clockwise.
// Pixels in the egg's staysAtHatch colours belong to the pet and stay put.
export function eggPieces(sp) {
  const g = sp.egg.cracks.at(-1) ?? sp.egg.whole;
  let x0 = N, x1 = 0, y0 = N, y1 = 0;
  for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) if (g[y][x] !== '.') {
    x0 = Math.min(x0, x); x1 = Math.max(x1, x + 1); y0 = Math.min(y0, y); y1 = Math.max(y1, y + 1);
  }
  const cx = (x0 + x1) / 2, cy = (y0 + y1) / 2;
  const pieceOf = (x, y) => {
    let a = Math.atan2(y + .5 - cy, x + .5 - cx) + Math.PI / 2;
    if (a < 0) a += Math.PI * 2;
    return Math.floor(a / (Math.PI * 2) * 7) % 7;
  };
  const pieces = Array.from({ length: 7 }, (_, k) => ({ px: [], a: (k + .5) / 7 * Math.PI * 2 - Math.PI / 2 }));
  const stays = [];
  for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) {
    const c = g[y][x];
    if (c === '.') continue;
    if (sp.egg.stays.includes(c)) stays.push([x, y, c]);
    else pieces[pieceOf(x, y)].px.push([x, y, c]);
  }
  return { pieces, stays, pieceOf };
}

// Slivers: bits of a piece, three pixels or fewer, that don't touch the rest
// of it. They read as crumbs rather than pieces of shell.
export function slivers(sp) {
  const { pieces } = eggPieces(sp);
  const out = [];
  pieces.forEach(({ px }, k) => {
    const at = new Set(px.map(([x, y]) => y * N + x)), seen = new Set();
    for (const [x0, y0] of px) {
      if (seen.has(y0 * N + x0)) continue;
      const bit = [], stack = [[x0, y0]];
      while (stack.length) {
        const [x, y] = stack.pop(), key = y * N + x;
        if (seen.has(key) || !at.has(key)) continue;
        seen.add(key); bit.push([x, y]);
        stack.push([x + 1, y], [x - 1, y], [x, y + 1], [x, y - 1]);
      }
      if (bit.length <= 3 && bit.length < px.length) out.push({ piece: k + 1, px: bit });
    }
  });
  return out;
}

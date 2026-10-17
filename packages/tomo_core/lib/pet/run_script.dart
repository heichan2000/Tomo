import 'dart:math' as math;

import '../art/compose.dart';
import '../art/drawings.dart';
import '../art/pixel_art.dart';
import '../look/palette.dart';
import '../rewards/rewards.dart';
import 'beat.dart';
import 'pet_look.dart';
import 'reward_colours.dart';
import 'species.dart';

/// What a beat run shows at each moment (spec §7.5, ADR-0019): the pet, the
/// effects drawn around it in pet pixels, "+EXP", the plate, the EXP bar and
/// the dither. A pure function of the run and the time since it started, so a
/// screen only has to ask [at] each frame.
///
/// The timings, sprites and physics are those of
/// [Pixel reward effects](https://github.com/heichan2000/Tomo/issues/39#issuecomment-5945625543)
/// and its hatch amendment, as the approved Tomo Pixel Screens play them.
final class RunScript {
  RunScript(
    this.run, {
    required this.species,
    required this.expBefore,
    required this.theme,
    required this.movement,
  }) {
    var start = 0;
    var exp = expBefore;
    for (final beat in run) {
      _starts.add(start);
      _exps.add(exp);
      start += _length(beat);
      exp = switch (beat) {
        BlockCredited(exp: final grant) ||
        TaskCompleted(bonusExp: final grant) => addExp(exp, grant),
        _ => exp,
      };
    }
    _exps.add(exp);
    _length_ = start;
  }

  /// The beats, in the order they play.
  final List<Beat> run;
  final Species species;

  /// The pet's EXP before the run's first beat.
  final int expBefore;
  final ThemeName theme;
  final Movement movement;

  final _starts = <int>[];

  /// The EXP as each beat starts, and after the last.
  final _exps = <int>[];
  late final int _length_;

  /// When the run reaches its payload: the choices (or, after the hatch, the
  /// naming) step in, and the run counts as finished.
  Duration get length => Duration(milliseconds: _length_);

  /// When everything is still: the payload is in and the last beat's
  /// effects have gone. Skipping the run lands here.
  Duration get end => Duration(
    milliseconds: math.max(_length_ + 280, _starts.last + _settles(run.last)),
  );

  /// What shows [elapsed] after the run started.
  RunFrame at(Duration elapsed) {
    final t = elapsed.inMilliseconds;
    var beat = 0;
    while (beat + 1 < run.length && t >= _starts[beat + 1]) {
      beat++;
    }
    final frame = _beatFrame(beat, t - _starts[beat]);
    if (t < _length_) return frame;
    return frame._payloadIn(_stepIn(t - _length_));
  }

  /// The payload [v] ms after it starts stepping in: up 4 UI pixels into
  /// place over 280 ms, decelerating; under reduce motion a 150 ms cross-fade.
  StepIn _stepIn(int v) {
    if (_reduced) return StepIn(dy: 0, opacity: math.min(1, v / 150));
    final k = math.min(1, v / 280);
    return StepIn(dy: _round(4 * math.pow(1 - k, 3).toDouble()));
  }

  RunFrame _beatFrame(int beat, int u) {
    final before = _exps[beat], after = _exps[beat + 1];
    final last = beat == run.length - 1;
    final length = _length(run[beat]);
    final stage = _stageAt(beat);
    switch (run[beat]) {
      case BlockCredited():
        return RunFrame(
          beat: beat,
          // Before the hatch the egg holds still at its last crack (§17 C6).
          pet: _hatches
              ? ShownEgg(picture: _lastCrack)
              : ShownStage(stage: stage, face: Face.pleased),
          hatched: !_hatches,
          dither: false,
          level: levelForExp(before),
          bar: _fill(u, 300, _lit(before), _litReached(before, after), 70),
          gain: _rise(u, 100, 1200, after - before),
        );
      case LevelUp(:final level):
        return RunFrame(
          beat: beat,
          pet: ShownStage(stage: stage, face: Face.celebrating),
          dither: !last || u < length - 100,
          // The level the run started from, until the plate says the new one.
          level: u < 100 ? levelForExp(_exps[beat == 0 ? 0 : beat - 1]) : level,
          bar: u < 300
              ? const BarShown(lit: _barBlocks)
              : _fill(u, _reduced ? 300 : 400, 0, _lit(after), 90),
          plate: _plate(u, 100, 1840, level),
          sparkles: _levelSparkles(u - 150, _stageBox(stage)),
        );
      case TaskCompleted():
        final box = _stageBox(stage);
        return RunFrame(
          beat: beat,
          pet: ShownStage(stage: stage, face: Face.celebrating),
          dither: !last || u < length - 100,
          level: levelForExp(before),
          bar: _fill(u, 350, _lit(before), _litReached(before, after), 90),
          gain: _rise(u, 150, 1250, after - before),
          plate: _plate(u, 100, 2050, null),
          sparkles: _taskSparkles(u - 100, box),
          confetti: _confetti(u - 150, box, 36, seed: 3),
        );
      case Evolution(:final from, :final to):
        final (pet, sparkles, confetti) = _evolution(u, from, to);
        return RunFrame(
          beat: beat,
          pet: pet,
          dither: !last || u < length - 100,
          level: levelForExp(after),
          bar: BarShown(lit: _lit(after)),
          sparkles: sparkles,
          confetti: confetti,
        );
      case Hatch():
        final (pet, hatched, sparkles) = _hatch(u);
        final v = u - 2500;
        return RunFrame(
          beat: beat,
          pet: pet,
          cleared: true,
          hatched: hatched,
          dither: false,
          level: levelForExp(after),
          bar: BarShown(lit: _lit(after)),
          sparkles: sparkles,
          confetti: _confetti(v, _stageBox(1), 64, seed: 9),
          shell: _reduced ? const [] : _shell(v),
        );
    }
  }

  bool get _hatches => run.any((beat) => beat is Hatch);

  int get _lastCrack => artOf(species).egg.cracks.length;

  /// The hatch [u] ms in: the egg shakes three times, the last harder and
  /// faster; at 2.5 s it breaks with the pet already there, which brings its
  /// colour and two rings of large sparkles. Under reduce motion the egg
  /// cross-fades into the pet, and the sparkles hold still.
  (ShownPet, bool, List<SparkleShown>) _hatch(int u) {
    var shift = 0;
    for (final (start, step, length) in const [
      (300, 80, 480),
      (1100, 80, 480),
      (1800, 60, 600),
    ]) {
      if (u >= start && u < start + length) {
        shift = const [-1, 0, 1, 0][(u - start) ~/ step % 4];
      }
    }
    final egg = ShownEgg(picture: _lastCrack, shift: shift);
    const pet = ShownStage(stage: 1, face: Face.celebrating);
    final box = _stageBox(1);
    if (u < 2500) return (egg, false, const []);
    if (_reduced) {
      if (u < 3100) {
        final fade = CrossFade(
          from: ShownEgg(picture: _lastCrack),
          to: const ShownStage(stage: 1, face: Face.still),
          share: (u - 2500) / 600,
        );
        return (fade, false, const []);
      }
      return (pet, true, _still(u - 3100, 1800, box.ring(12, 7), 3));
    }
    final v = u - 2500;
    return (
      pet,
      true,
      [
        ..._burst(v, box),
        for (final (i, (x, y)) in box.ring(16, 14, math.pi / 16).indexed)
          ?_twinkle(v - 250 - i * 30, x, y, _large),
      ],
    );
  }

  /// The egg's shell [v] ms after it breaks: its last crack picture cut into
  /// seven pieces by angle around the middle of the egg, starting straight up
  /// and going clockwise, each flying out along its angle and falling, in
  /// 50 ms whole-pixel steps, gone after 1.5 s. The pet's own colours (its
  /// peeking eyes) stay behind (ADR-0019).
  List<ShellPixel> _shell(int v) {
    if (v < 0 || v > 1500) return const [];
    final q = (v / 50).floor() * 50;
    final pieces = _pieces.putIfAbsent(species, () => _cut(artOf(species)));
    return [
      for (final (j, piece) in pieces.indexed)
        for (final (x, y, colour) in piece)
          ShellPixel(
            x: x + _round(math.cos(_pieceAngle(j)) * 0.05 * q),
            y:
                y +
                _round(
                  (math.sin(_pieceAngle(j)) * 0.05 - 0.045) * q +
                      0.5 * 0.00016 * q * q,
                ),
            colour: colour,
          ),
    ];
  }

  /// The evolution [u] ms in: small sparkles closing in for 0.6 s, the
  /// flicker alone, then the burst on the new stage. Under reduce motion, the
  /// 0.6 s cross-fade and still sparkles.
  (ShownPet, List<SparkleShown>, List<ConfettiPiece>) _evolution(
    int u,
    int from,
    int to,
  ) {
    final old = ShownStage(stage: from, face: Face.resting);
    final grown = ShownStage(stage: to, face: Face.celebrating);
    final burst = _stageBox(to);
    if (_reduced) {
      if (u < 600) return (old, const [], const []);
      if (u < 1200) {
        final fade = CrossFade(
          from: old,
          to: ShownStage(stage: to, face: Face.still),
          share: (u - 600) / 600,
        );
        return (fade, const [], const []);
      }
      return (grown, _still(u - 1200, 1600, burst.ring(10, 6), 3), const []);
    }
    if (u < 600) {
      final box = _stageBox(from);
      return (
        old,
        [
          for (var j = 0; j < 3; j++)
            for (final (x, y) in box.ring(8, 12 - 4 * j, j * 0.2))
              ?_twinkle(u - j * 200, x, y, _small),
        ],
        const [],
      );
    }
    if (u < 2300) {
      // Nothing else moves while it plays.
      final swaps = _flicker.where((at) => u - 600 >= at).length;
      return (
        ShownStage(stage: swaps.isOdd ? to : from, face: Face.still),
        const [],
        const [],
      );
    }
    return (
      grown,
      _burst(u - 2300, burst),
      _confetti(u - 2300, burst, 44, seed: 7),
    );
  }

  /// Twelve large sparkles opening in a wave, 45 ms apart, and eight medium
  /// ones inside them from 420 ms.
  List<SparkleShown> _burst(int v, _Box box) => [
    for (final (i, (x, y)) in box.ring(12, 6).indexed)
      ?_twinkle(v - i * 45, x, y, _large),
    for (final (i, (x, y)) in box.ring(8, 1, math.pi / 8).indexed)
      ?_twinkle(v - 420 - i * 45, x, y, _medium),
  ];

  /// Three medium sparkles, opening 200 ms apart, once each. Under reduce
  /// motion, the level-up's six, held still.
  List<SparkleShown> _taskSparkles(int v, _Box box) {
    if (_reduced) return _still(v, 1800, box.ring(6, 5, math.pi / 6), 2);
    return [
      for (final (i, (x, y)) in box.ring(3, 6, -math.pi / 3).indexed)
        ?_twinkle(v - i * 200, x, y, _medium),
    ];
  }

  /// [count] pieces of confetti [v] ms after they launch from the top of the
  /// pet's head: squares that flutter, falling in 50 ms whole-pixel steps,
  /// each gone 2.4 s after it set off. None under reduce motion. [seed] fixes
  /// where each one goes, so every frame of a run agrees.
  List<ConfettiPiece> _confetti(
    int v,
    _Box box,
    int count, {
    required int seed,
  }) {
    if (_reduced || v < 0) return const [];
    final colours = _confettiColours;
    final random = _Mulberry32(seed);
    double between(double low, double high) =>
        low + (high - low) * random.next();
    final pieces = <ConfettiPiece>[];
    for (var i = 0; i < count; i++) {
      final x0 = box.cx + between(-4, 4), y0 = box.top + between(0, 4);
      final vx = between(-0.042, 0.042), vy = between(-0.1, -0.055);
      final delay = between(0, 140);
      final colour = colours[(random.next() * 97).floor() % colours.length];
      final flight = v - delay;
      if (flight < 0 || flight > 2400) continue;
      final q = (flight / 50).floor() * 50;
      // Every third piece is one pixel; the others turn edge-on and back
      // every 100 ms.
      final edgeOn = (q ~/ 100).isOdd;
      pieces.add(
        ConfettiPiece(
          x: _round(x0 + vx * q),
          y: _round(y0 + vy * q + 0.5 * 0.00012 * q * q),
          width: i % 3 == 0 ? 1 : 2,
          height: i % 3 == 0 || edgeOn ? 1 : 2,
          colour: colour,
        ),
      );
    }
    return pieces;
  }

  late final _confettiColours = confettiColours(theme, species);

  /// Six medium sparkles in a ring, opening 170 ms apart, each twice.
  List<SparkleShown> _levelSparkles(int v, _Box box) {
    final ring = box.ring(6, 5, math.pi / 6);
    if (_reduced) return _still(v, 1500, ring, 2);
    return [
      for (final (i, (x, y)) in ring.indexed)
        for (final open in [i * 170, i * 170 + 720])
          ?_twinkle(v - open, x, y, _medium),
    ];
  }

  /// [ring] held still at [frame], fading in and out over 200 ms across
  /// [length] ms: the sparkles under reduce motion.
  List<SparkleShown> _still(
    int v,
    int length,
    List<(int, int)> ring,
    int frame,
  ) {
    if (v < 0 || v >= length) return const [];
    final opacity = _fadeInOut(v, 0, length, 200);
    return [
      for (final (x, y) in ring)
        SparkleShown(x: x, y: y, frame: frame, opacity: opacity),
    ];
  }

  /// The box around stage [stage]'s picture, standing still.
  _Box _stageBox(int stage) => _boxes.putIfAbsent((
    species,
    stage,
  ), () => _Box.around(composeStage(artOf(species), stage - 1)));

  /// The stage shown during [beat]: an evolution still to come holds the old
  /// one until it starts (spec §7.2).
  int _stageAt(int beat) {
    for (final later in run.skip(beat)) {
      if (later is Evolution) return later.from;
    }
    return stageForExp(_exps[beat]);
  }

  bool get _reduced => movement == Movement.reduced;

  int _length(Beat beat) => switch (beat) {
    BlockCredited() => 1300,
    LevelUp() => 2200,
    TaskCompleted() => 2450,
    Evolution() => _reduced ? 2700 : 4000,
    // To the naming.
    Hatch() => _reduced ? 4300 : 3700,
  };

  /// How long [beat] takes to fall still, its effects gone, when it is the
  /// last of its run.
  int _settles(Beat beat) => switch (beat) {
    BlockCredited() => 1300,
    LevelUp() => 2200,
    TaskCompleted() => _reduced ? 1900 : 2700,
    Evolution() => _reduced ? 2800 : 4850,
    Hatch() => _reduced ? 4900 : 5050,
  };

  /// "+EXP" for [exp], rising from [start] a UI pixel every 60 ms to 9 and
  /// settling at 8, gone at [end]. Under reduce motion it cross-fades in place.
  Rise? _rise(int u, int start, int end, int exp) {
    if (u < start || u >= end) return null;
    if (_reduced) {
      return Rise(exp: exp, dy: 0, opacity: _fadeInOut(u, start, end, 150));
    }
    return Rise(exp: exp, dy: _stepAt(_riseSteps, 60, u - start));
  }

  /// The plate for [level] (null: Task done), popping in from [start] in
  /// steps of -4 -2 0 +1 0 UI pixels, 70 ms each, then dropping 1 and 2 and
  /// gone at [end]. Under reduce motion it cross-fades in place.
  Plate? _plate(int u, int start, int end, int? level) {
    final gone = _reduced ? end - 40 : end;
    if (u < start || u >= gone) return null;
    if (_reduced) {
      return Plate(
        level: level,
        dy: 0,
        opacity: _fadeInOut(u, start, gone, 200),
      );
    }
    final out = end - 140;
    return Plate(
      level: level,
      dy: u < out
          ? _stepAt(const [-4, -2, 0, 1, 0], 70, u - start)
          : _stepAt(const [-1, -2], 70, u - out),
    );
  }

  /// The bar lighting from [from] blocks to [to], one every [ms] from [start]:
  /// each new block pops for its step. Under reduce motion it jumps.
  BarShown _fill(int u, int start, int from, int to, int ms) {
    if (u < start) return BarShown(lit: from);
    if (_reduced) return BarShown(lit: to);
    final k = (u - start) ~/ ms;
    return k < to - from
        ? BarShown(lit: from + k + 1, pop: from + k)
        : BarShown(lit: to);
  }
}

/// How many of the bar's blocks [exp] lights: one per whole 30 EXP into its
/// level (§17 C80).
int _lit(int exp) => exp % expPerLevel * _barBlocks ~/ expPerLevel;

/// The blocks lit on reaching [after] from [before]: all of them when a new
/// level was reached, for the level-up to empty and refill.
int _litReached(int before, int after) =>
    levelForExp(after) > levelForExp(before) ? _barBlocks : _lit(after);

const _barBlocks = 20;

/// The sparkle's frames, one every 70 ms: medium plays 1 2 3 3 2 1, large
/// 1 2 3 4 4 3 2 1, small 1 2 2 1 (frames counted from 0 here).
const _medium = [0, 1, 2, 2, 1, 0];
const _large = [0, 1, 2, 3, 3, 2, 1, 0];
const _small = [0, 1, 1, 0];

/// When the evolution flicker swaps old and new: five times, so it ends on
/// the new stage (ADR-0019).
const _flicker = [0, 500, 950, 1350, 1700];

/// The sparkle at ([x], [y]) [v] ms after it opened, playing [frames]; null
/// before it opens and once it has closed.
SparkleShown? _twinkle(int v, int x, int y, List<int> frames) {
  if (v < 0 || v ~/ 70 >= frames.length) return null;
  return SparkleShown(x: x, y: y, frame: frames[v ~/ 70]);
}

final _boxes = <(Species, int), _Box>{};

final _pieces = <Species, List<List<(int, int, int)>>>{};

/// The direction the shell's piece [j] flies: the middle of its slice.
double _pieceAngle(int j) => (j + 0.5) / 7 * 2 * math.pi - math.pi / 2;

/// [art]'s last egg picture cut into the seven pieces of the shell rule:
/// by angle around the middle of its bounding box, starting straight up,
/// clockwise.
List<List<(int, int, int)>> _cut(SpeciesArt art) {
  final rows = gridRows(art.egg.cracks.last);
  final box = _Box.around(rows);
  final cx = (box.left + box.right + 1) / 2;
  final cy = (box.top + box.bottom + 1) / 2;
  final pieces = List.generate(7, (_) => <(int, int, int)>[]);
  for (var y = 0; y < rows.length; y++) {
    for (var x = 0; x < rows[y].length; x++) {
      final c = rows[y][x];
      if (c == '.' || art.egg.staysAtHatch.contains(c)) continue;
      var a = math.atan2(y + 0.5 - cy, x + 0.5 - cx) + math.pi / 2;
      if (a < 0) a += 2 * math.pi;
      pieces[(a / (2 * math.pi) * 7).floor() % 7].add((x, y, art.colours[c]!));
    }
  }
  return pieces;
}

/// The bounding box of a picture on the pet grid, which the effects are laid
/// out around.
final class _Box {
  _Box.around(List<String> rows) {
    var l = 48, t = 48, r = -1, b = -1;
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        if (rows[y][x] == '.') continue;
        l = math.min(l, x);
        r = math.max(r, x);
        t = math.min(t, y);
        b = math.max(b, y);
      }
    }
    left = l;
    top = t;
    right = r;
    bottom = b;
  }

  late final int left, top, right, bottom;

  int get cx => _round((left + right) / 2);
  int get cy => _round((top + bottom) / 2);
  double get hx => (right - left + 1) / 2;
  double get hy => (bottom - top + 1) / 2;

  /// [n] points evenly round the box, [grow] pixels out from its edges,
  /// starting straight up turned by [turn], clockwise.
  List<(int, int)> ring(int n, num grow, [double turn = 0]) => [
    for (var i = 0; i < n; i++)
      (
        cx + _round(math.cos(_angle(i, n, turn)) * (hx + grow)),
        cy + _round(math.sin(_angle(i, n, turn)) * (hy + grow)),
      ),
  ];

  static double _angle(int i, int n, double turn) =>
      turn + i / n * 2 * math.pi - math.pi / 2;
}

/// The small random number generator the approved prototypes drew confetti
/// with (mulberry32), so a seed gives the same pieces they showed.
final class _Mulberry32 {
  _Mulberry32(int seed) : _a = seed & _mask;

  int _a;

  static const _mask = 0xFFFFFFFF;

  static int _mul(int a, int b) => (a * b) & _mask;

  /// The next number from 0 up to 1.
  double next() {
    _a = (_a + 0x6D2B79F5) & _mask;
    var t = _mul(_a ^ (_a >> 15), 1 | _a);
    t = ((t + _mul(t ^ (t >> 7), 61 | t)) & _mask) ^ t;
    return ((t ^ (t >> 14)) & _mask) / 4294967296;
  }
}

/// Rounds halves up, as the approved prototypes did.
int _round(double v) => (v + 0.5).floor();

const _riseSteps = [1, 2, 3, 4, 5, 6, 7, 8, 9, 8];

/// [steps]' entry [u] ms in, one every [ms], holding the last.
int _stepAt(List<int> steps, int ms, int u) =>
    steps[(u ~/ ms).clamp(0, steps.length - 1)];

/// Fully shown from [start] to [end], fading in and out over [fade] ms.
double _fadeInOut(int u, int start, int end, int fade) {
  if (u < start || u >= end) return 0;
  final a = (u - start) / fade, b = (end - u) / fade;
  return a < b ? (a < 1 ? a : 1) : (b < 1 ? b : 1);
}

/// One moment of a run.
final class RunFrame {
  const RunFrame({
    required this.beat,
    required this.pet,
    this.hatched = true,
    this.cleared = false,
    required this.dither,
    required this.level,
    required this.bar,
    this.gain,
    this.plate,
    this.sparkles = const [],
    this.confetti = const [],
    this.shell = const [],
    this.payload,
  });

  /// Which beat of the run is playing.
  final int beat;

  /// The pet, or the egg, as the run shows it. Null once the payload has
  /// stepped in: the screen shows its own pet again.
  final ShownPet? pet;

  /// Whether the pet has hatched on screen: the accent is the pet's own, not
  /// the egg's grey. Until the hatch's burst, it has not.
  final bool hatched;

  /// Whether the hatch has cleared the screen of chrome and buttons.
  final bool cleared;

  /// Whether the dither covers the chrome behind the pet (a Moment).
  final bool dither;

  /// The level shown with the bar.
  final int level;

  /// The 20-block EXP bar.
  final BarShown bar;

  /// "+EXP", rising beside the pet's head.
  final Rise? gain;

  /// The plate under the EXP bar: "Level 13" or "Task done".
  final Plate? plate;

  /// The sparkles showing, on the pet grid.
  final List<SparkleShown> sparkles;

  /// The confetti in the air, on the pet grid.
  final List<ConfettiPiece> confetti;

  /// The egg's shell flying apart at the hatch, on the pet grid.
  final List<ShellPixel> shell;

  /// The choices (or, after the hatch, the naming) stepping in. Null until
  /// the run reaches them.
  final StepIn? payload;

  RunFrame _payloadIn(StepIn payload) => RunFrame(
    beat: beat,
    pet: null,
    hatched: hatched,
    cleared: cleared,
    dither: false,
    level: level,
    bar: bar,
    gain: gain,
    plate: plate,
    sparkles: sparkles,
    confetti: confetti,
    shell: shell,
    payload: payload,
  );
}

/// One pixel of the breaking shell: pixel ([x], [y]) of the pet grid in
/// [colour] (`0xAARRGGBB`).
final class ShellPixel {
  const ShellPixel({required this.x, required this.y, required this.colour});

  final int x, y, colour;
}

/// Something stepping into place: [dy] UI pixels below it, at [opacity]
/// (only reduce motion fades it).
final class StepIn {
  const StepIn({required this.dy, this.opacity = 1});

  final int dy;
  final double opacity;

  @override
  bool operator ==(Object other) =>
      other is StepIn && other.dy == dy && other.opacity == opacity;

  @override
  int get hashCode => Object.hash(dy, opacity);

  @override
  String toString() => 'StepIn(dy $dy, opacity $opacity)';
}

/// One piece of confetti: a [width] by [height] block of pet pixels whose top
/// left is pixel ([x], [y]) of the pet grid, in [colour] (`0xAARRGGBB`).
final class ConfettiPiece {
  const ConfettiPiece({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.colour,
  });

  final int x, y, width, height, colour;

  @override
  bool operator ==(Object other) =>
      other is ConfettiPiece &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height &&
      other.colour == colour;

  @override
  int get hashCode => Object.hash(x, y, width, height, colour);
}

/// One sparkle, centred on pixel ([x], [y]) of the pet grid (which may lie
/// outside the grid), showing [frame] (0 to 3) of the sparkle drawing at
/// [opacity] (only reduce motion fades it).
final class SparkleShown {
  const SparkleShown({
    required this.x,
    required this.y,
    required this.frame,
    this.opacity = 1,
  });

  final int x, y, frame;
  final double opacity;

  @override
  bool operator ==(Object other) =>
      other is SparkleShown &&
      other.x == x &&
      other.y == y &&
      other.frame == frame &&
      other.opacity == opacity;

  @override
  int get hashCode => Object.hash(x, y, frame, opacity);

  @override
  String toString() => 'Sparkle($x, $y, frame $frame, opacity $opacity)';
}

/// The plate under the EXP bar, saying "Level [level]", or "Task done" when
/// [level] is null; raised [dy] UI pixels above its place (below it when
/// negative), at [opacity] (only reduce motion fades it).
final class Plate {
  const Plate({this.level, required this.dy, this.opacity = 1});

  final int? level;
  final int dy;
  final double opacity;

  @override
  bool operator ==(Object other) =>
      other is Plate &&
      other.level == level &&
      other.dy == dy &&
      other.opacity == opacity;

  @override
  int get hashCode => Object.hash(level, dy, opacity);

  @override
  String toString() =>
      'Plate(${level == null ? 'Task done' : 'Level $level'}, dy $dy, '
      'opacity $opacity)';
}

/// "+[exp] EXP" in the accent, raised [dy] UI pixels from where it starts,
/// at [opacity] (only reduce motion fades it).
final class Rise {
  const Rise({required this.exp, required this.dy, this.opacity = 1});

  final int exp;
  final int dy;
  final double opacity;

  @override
  bool operator ==(Object other) =>
      other is Rise &&
      other.exp == exp &&
      other.dy == dy &&
      other.opacity == opacity;

  @override
  int get hashCode => Object.hash(exp, dy, opacity);

  @override
  String toString() => 'Rise(+$exp, dy $dy, opacity $opacity)';
}

/// The EXP bar: [lit] blocks in the accent, and the block at [pop] standing
/// one UI pixel taller as it lights.
final class BarShown {
  const BarShown({required this.lit, this.pop});

  final int lit;
  final int? pop;

  @override
  bool operator ==(Object other) =>
      other is BarShown && other.lit == lit && other.pop == pop;

  @override
  int get hashCode => Object.hash(lit, pop);

  @override
  String toString() => 'BarShown($lit${pop == null ? '' : ', pop $pop'})';
}

/// What stands in the pet's spot.
sealed class ShownPet {
  const ShownPet();
}

/// The pet at [stage] (1 to 4) with [face].
final class ShownStage extends ShownPet {
  const ShownStage({required this.stage, required this.face});

  final int stage;
  final Face face;

  @override
  bool operator ==(Object other) =>
      other is ShownStage && other.stage == stage && other.face == face;

  @override
  int get hashCode => Object.hash(stage, face);

  @override
  String toString() => 'ShownStage($stage, ${face.name})';
}

/// Two pictures cross-fading under reduce motion: [to] showing at [share]
/// (0 to 1) over [from].
final class CrossFade extends ShownPet {
  const CrossFade({required this.from, required this.to, required this.share});

  final ShownPet from;
  final ShownPet to;
  final double share;

  @override
  bool operator ==(Object other) =>
      other is CrossFade &&
      other.from == from &&
      other.to == to &&
      other.share == share;

  @override
  int get hashCode => Object.hash(from, to, share);

  @override
  String toString() => 'CrossFade($from to $to, $share)';
}

/// The egg showing [picture] (0 whole, then each crack), slid [shift] pixels
/// sideways: the shake before the hatch.
final class ShownEgg extends ShownPet {
  const ShownEgg({required this.picture, this.shift = 0});

  final int picture;
  final int shift;

  @override
  bool operator ==(Object other) =>
      other is ShownEgg && other.picture == picture && other.shift == shift;

  @override
  int get hashCode => Object.hash(picture, shift);

  @override
  String toString() => 'ShownEgg($picture, shift $shift)';
}

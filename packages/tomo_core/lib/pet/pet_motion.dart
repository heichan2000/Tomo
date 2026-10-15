import 'dart:math' as math;

import '../art/compose.dart';
import '../art/pixel_art.dart';
import 'pet_look.dart';

/// How the pet on screen moves from moment to moment (spec §7.3, §7.6,
/// ADR-0018): the face's own movement, the blink, the idle moves, the hop and
/// the egg's wobble, as poses over time.
///
/// It lives only in the pet widget and is never saved. Nothing here is a beat
/// or part of `look`: it takes the look as given and decides which pose shows
/// when. Time is whatever the widget's own clock says, as a [Duration] since
/// it started; nothing here reads a real clock, so it never knows the time of
/// day or how long the user was away.
///
/// Call [show] whenever the look changes, [hello] when the app opens onto the
/// pet, [tap] when the pet is tapped, then read [pose] or [eggShift] and ask
/// [nextChange] when to look again.
final class PetMotion {
  PetMotion(PetLook look, {math.Random? random, Duration now = Duration.zero})
    : _random = random ?? math.Random(),
      _look = look {
    // The blinks draw from their own stream, so when they are noticed never
    // changes which idle move or wobble comes next.
    _blinks = math.Random(_random.nextInt(1 << 32));
    _blinkAt = now.inMilliseconds + _blinkGap();
    _begin(now.inMilliseconds);
  }

  final math.Random _random;
  late final math.Random _blinks;

  PetLook _look;
  PetLook get look => _look;

  /// When the face began, for the movements that start with it: the Pleased
  /// bob, the Celebrating jumps.
  int _faceSince = 0;

  /// The one-off move playing now, if any.
  Act? _act;
  int _actSince = 0;

  /// The idle move to come, and when. Null unless the pet may idle.
  Act? _nextIdle;

  /// The last idle move played, which the next one may not be.
  Act? _lastIdle;
  int? _idleAt;

  int _blinkAt = 0;

  /// The egg's wobble playing now, and the next one.
  int? _wobbleSince;
  int? _wobbleAt;

  /// The look changed. A new face starts its own movement and stops any move
  /// in play; the idle moves and the egg's wobble are scheduled afresh, or
  /// stop, as the new look allows.
  void show(PetLook look, Duration now) {
    final old = _look;
    _look = look;
    final sameFace = switch ((old, look)) {
      (final HatchedLook a, final HatchedLook b) => a.face == b.face,
      (EggLook(), EggLook()) => true,
      _ => false,
    };
    if (!sameFace) _begin(now.inMilliseconds);
    // Calm pet turned on or off under a waiting egg.
    if (look is EggLook && !look.mayWobble) _wobbleSince = _wobbleAt = null;
    if (look is EggLook && look.mayWobble && _wobbleAt == null) {
      _wobbleAt = now.inMilliseconds + _idleGap();
    }
  }

  /// Starts the face's own movement over, as if the face had just begun: a
  /// beat that shows the face the pet already has (the block-done beat's
  /// Pleased over a running block's) still plays its bob.
  void restart(Duration now) => _begin(now.inMilliseconds);

  void _begin(int now) {
    _faceSince = now;
    _act = null;
    _wobbleSince = null;
    _nextIdle = _idleAt = _wobbleAt = null;
    switch (_look) {
      case HatchedLook(mayIdle: true):
        _scheduleIdle(after: now);
      case EggLook(mayWobble: true):
        _wobbleAt = now + _idleGap();
      case _:
        break;
    }
  }

  /// The hello: the hop, when the app opens onto the resting pet (§7.6).
  /// Returns whether it plays.
  bool hello(Duration now) => play(Act.hop, now);

  /// Plays [act] now, as the idle moves and the hop play: only on the resting
  /// pet, and not over a move in play. The hello is this with the hop; the
  /// debug pet screen uses it to show a move without waiting for it. The
  /// idle schedule is left as it was. Returns whether it plays.
  bool play(Act act, Duration now) {
    final t = now.inMilliseconds;
    _advance(t);
    final look = _look;
    if (look is! HatchedLook || !look.mayIdle || _actAt(t) != null) {
      return false;
    }
    _act = act;
    _actSince = t;
    return true;
  }

  /// A tap: the resting pet hops and the waiting egg wobbles. Taps during a
  /// move, during a block or a break, and under Calm pet do nothing. Returns
  /// whether something plays.
  bool tap(Duration now) {
    final t = now.inMilliseconds;
    _advance(t);
    final look = _look;
    if (look is EggLook) {
      if (!look.mayWobble || _wobbling(t)) return false;
      _wobbleSince = t;
      return true;
    }
    return play(Act.hop, now);
  }

  /// The move playing at [now]: a hop or an idle move.
  Act? playing(Duration now) {
    _advance(now.inMilliseconds);
    return _actAt(now.inMilliseconds);
  }

  /// The pose of the hatched pet at [now].
  Pose pose(Duration now) {
    final t = now.inMilliseconds;
    _advance(t);
    return _poseAt(t);
  }

  /// How far the egg sits from its place at [now], in pixels: the wobble.
  int eggShift(Duration now) {
    final t = now.inMilliseconds;
    _advance(t);
    return _eggShiftAt(t);
  }

  /// The next moment the picture may change after [now]. Never more than a
  /// second away, so a late timer costs no more than that.
  Duration nextChange(Duration now) {
    final t = now.inMilliseconds;
    _advance(t);
    final look = _look;
    final Object Function(int) at = look is EggLook ? _eggShiftAt : _poseAt;
    final current = at(t);
    var limit = t + 1000;
    for (final event in [_idleAt, _wobbleAt, _blinkAt]) {
      if (event != null && event > t && event < limit) limit = event;
    }
    for (var u = t + _step; u < limit; u += _step) {
      if (at(u) != current) return Duration(milliseconds: u);
    }
    return Duration(milliseconds: limit);
  }

  /// Every timing here is a whole number of these.
  static const _step = 10;

  // ---- moving the schedule along ----

  void _advance(int t) {
    final act = _act;
    if (act != null && t >= _actSince + _length(act)) _act = null;

    final idleAt = _idleAt;
    if (idleAt != null && t >= idleAt) {
      final busy = _act;
      if (busy != null) {
        // A hop is playing: the idle move waits a while longer.
        _idleAt = _actSince + _length(busy) + _idleGap();
      } else if (t < idleAt + _length(_nextIdle!)) {
        _act = _lastIdle = _nextIdle;
        _actSince = idleAt;
        _scheduleIdle(after: idleAt);
      } else {
        // Missed while the widget slept: let it go.
        _scheduleIdle(after: t);
      }
    }

    if (t >= _blinkAt + _blink) {
      _blinkAt += _blink + _blinkGap();
      // Asleep through more than one: start again from now.
      if (t >= _blinkAt + _blink) _blinkAt = t + _blinkGap();
    }

    final wobbleSince = _wobbleSince;
    if (wobbleSince != null && t >= wobbleSince + _wobble) _wobbleSince = null;
    final wobbleAt = _wobbleAt;
    if (wobbleAt != null && t >= wobbleAt) {
      if (t < wobbleAt + _wobble && _wobbleSince == null) {
        _wobbleSince = wobbleAt;
      }
      _wobbleAt = (_wobbleSince ?? t) + _idleGap();
    }
  }

  void _scheduleIdle({required int after}) {
    final choices = [
      for (final act in Act.idleMoves)
        if (act != _lastIdle) act,
    ];
    _nextIdle = choices[_random.nextInt(choices.length)];
    _idleAt = after + _idleGap();
  }

  /// 15 to 30 seconds (§7.6).
  int _idleGap() => _between(15000, 30000);

  /// 2.6 to 6.4 seconds from one blink to the next (§7.3).
  int _blinkGap() => _between(2600, 6400, _blinks);

  /// A random time from [low] to [high] ms, in whole steps.
  int _between(int low, int high, [math.Random? random]) =>
      low + (random ?? _random).nextInt((high - low) ~/ _step + 1) * _step;

  Act? _actAt(int t) {
    final act = _act;
    if (act == null || t < _actSince || t >= _actSince + _length(act)) {
      return null;
    }
    return act;
  }

  bool _wobbling(int t) {
    final since = _wobbleSince;
    return since != null && t >= since && t < since + _wobble;
  }

  // ---- what shows at a moment, given the schedule ----

  bool get _reduced => _look.movement == Movement.reduced;

  int _eggShiftAt(int t) {
    final since = _wobbleSince;
    if (since == null || t < since || t >= since + _wobble) return 0;
    return (t - since) < 150 ? -1 : 1;
  }

  Pose _poseAt(int t) {
    final look = _look;
    if (look is! HatchedLook) return Pose.rest;
    final act = _actAt(t);
    if (act != null) return _actPose(act, t - _actSince, _breath(t));
    return _facePose(look.face, t);
  }

  /// The breath: what rides with the head down a pixel, then up, 0.8 s each
  /// way (1.6 s under reduce motion).
  int _breath(int t, {bool slow = false}) =>
      (t ~/ (slow || _reduced ? 1600 : 800)) % 2;

  Pose _facePose(Face face, int t) {
    final since = t - _faceSince;
    switch (face) {
      case Face.resting:
        final blink = t >= _blinkAt && t < _blinkAt + _blink;
        return Pose(
          eyes: blink ? EyeShape.blink : EyeShape.resting,
          drop: _breath(t),
        );
      case Face.pleased:
        // One bob as the face begins, then the breath.
        final lift = _reduced
            ? (since < 210 ? 1 : 0)
            : _stepAt(const [1, 2, 1], 70, since);
        return Pose(
          eyes: EyeShape.pleased,
          lift: lift,
          drop: lift == 0 ? _breath(t) : 0,
        );
      case Face.drowsy:
        return Pose(eyes: EyeShape.drowsy, drop: 1 + _breath(t, slow: true));
      case Face.celebrating:
        final v = since % 900;
        if (_reduced) {
          return Pose(eyes: EyeShape.pleased, lift: v < 280 ? 1 : 0);
        }
        final k = v ~/ 70;
        if (k < _jump.length) {
          return Pose(
            eyes: EyeShape.pleased,
            lift: _jump[k],
            extra: _jump[k] >= 2 ? 1 : 0,
          );
        }
        // The head lands a beat late.
        return Pose(eyes: EyeShape.pleased, drop: k < _jump.length + 2 ? 1 : 0);
      case Face.still:
        return Pose.rest;
    }
  }

  Pose _actPose(Act act, int u, int breath) {
    switch (act) {
      case Act.hop:
        final lift = _reduced
            ? (u < 210 ? 1 : 0)
            : _stepAt(const [1, 2, 1], 70, u);
        return Pose(eyes: EyeShape.pleased, lift: lift);
      case Act.glance:
        final x = u >= 150 && u < 850
            ? -1
            : u >= 1000 && u < 1700
            ? 1
            : 0;
        return Pose(eyesX: x, drop: breath);
      case Act.lookUp:
        return Pose(eyesY: u >= 100 && u < 1100 ? -1 : 0, drop: breath);
      case Act.doubleBlink:
        final shut = u < 150 || (u >= 300 && u < 450);
        return Pose(
          eyes: shut ? EyeShape.blink : EyeShape.resting,
          drop: breath,
        );
      case Act.twitch:
        final up = _reduced
            ? (u < 200 ? 1 : 0)
            : _stepAt(const [1, 0, 1, 0], 120, u);
        return Pose(twitch: up, drop: breath);
      case Act.wiggle:
        final x = _reduced
            ? (u < 300 ? -1 : 0)
            : _stepAt(const [-1, 0, 1, 0, -1, 0, 1, 0], 100, u);
        return Pose(wiggle: x, drop: breath);
    }
  }

  int _length(Act act) => switch (act) {
    Act.hop => 600,
    Act.glance => 1900,
    Act.lookUp => 1300,
    Act.doubleBlink => 450,
    Act.twitch => _reduced ? 200 : 480,
    Act.wiggle => _reduced ? 300 : 800,
  };

  static const _jump = [1, 2, 3, 3, 2, 1];

  /// One blink, eyes shut.
  static const _blink = 150;

  /// The egg's wobble: a pixel left, then right, 150 ms each.
  static const _wobble = 300;
}

/// The one-off moves the resting pet plays: the hop (the hello and a tap) and
/// the five idle moves (§7.6).
enum Act {
  hop,
  glance,
  lookUp,
  doubleBlink,
  twitch,
  wiggle;

  /// One of these every 15 to 30 seconds, never the same twice in a row.
  static const idleMoves = [glance, lookUp, doubleBlink, twitch, wiggle];
}

/// [seq]'s value [u] ms in, one entry per [ms]; 0 once it has run out.
int _stepAt(List<int> seq, int ms, int u) {
  if (u < 0) return 0;
  final k = u ~/ ms;
  return k < seq.length ? seq[k] : 0;
}

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:tomo_core/notifications/haptics.dart';
import 'package:tomo_core/pet/run_script.dart';

/// How a beat run ended. Either way the screen marks it seen (spec §7.4).
enum RunEnd { finished, skipped }

/// Plays a beat run on screen (spec §7.4, §7.5): its [script] frame by
/// frame, one beat at a time, never overlapping. Each beat fires one reward
/// tap as it starts. [onEnd] is told once, when the run reaches its payload
/// (the choices, or the naming) or is skipped; the last beat's effects then
/// play out under the payload, and the player falls still.
///
/// Listen to it and paint [frame]. [speed] slows it down, for the debug
/// beats screen only.
class RunPlayer extends ChangeNotifier {
  RunPlayer({
    required this.script,
    required TickerProvider vsync,
    required this._haptics,
    this.onEnd,
    this.speed = 1,
  }) : _frame = script.at(Duration.zero) {
    _ticker = vsync.createTicker(_tick);
  }

  final RunScript script;
  final HapticPlayer _haptics;
  final ValueChanged<RunEnd>? onEnd;
  final double speed;

  late final Ticker _ticker;

  RunFrame _frame;

  /// What shows now.
  RunFrame get frame => _frame;

  /// The beats that have fired their tap.
  var _tapped = 0;

  /// How the run ended, once it has.
  RunEnd? get ended => _ended;
  RunEnd? _ended;

  /// Whether anything is still moving.
  bool get playing => _ticker.isActive;

  /// Starts the run from its first beat.
  void start() {
    _ticker.start();
    _show(Duration.zero);
  }

  /// Jumps to the payload with everything still: a tap anywhere does this.
  void skip() {
    if (_ended == null) _end(RunEnd.skipped);
    _ticker.stop();
    _frame = script.at(script.end);
    notifyListeners();
  }

  void _tick(Duration elapsed) {
    final t = elapsed * speed;
    // Stopped first, so listeners told of the last frame see it still.
    if (t >= script.end) _ticker.stop();
    _show(t);
  }

  void _show(Duration t) {
    _frame = script.at(t);
    while (_tapped <= _frame.beat) {
      _tapped++;
      _haptics.play(Haptic.rewardTap);
    }
    if (_ended == null && t >= script.length) _end(RunEnd.finished);
    notifyListeners();
  }

  void _end(RunEnd end) {
    _ended = end;
    onEnd?.call(end);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

/// Covers [child] while [player]'s run plays, so a tap anywhere skips it
/// (spec §7.4). Once the run has ended, taps reach [child] again.
class SkipRun extends StatelessWidget {
  const SkipRun({super.key, required this.player, required this.child});

  final RunPlayer player;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: player,
    builder: (context, child) => Stack(
      children: [
        child!,
        if (player.ended == null)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: player.skip,
            ),
          ),
      ],
    ),
    child: child,
  );
}

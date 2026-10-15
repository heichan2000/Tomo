import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:tomo_core/art/compose.dart';
import 'package:tomo_core/art/drawings.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/pet/pet_look.dart';
import 'package:tomo_core/pet/pet_motion.dart';
import 'package:tomo_core/pet/species.dart';

import '../ui/whole_dots.dart';

/// The spots a pet is painted in (spec §7.1).
abstract final class PetSpot {
  static const home = 192.0;
  static const focus = 168.0;
  static const hatch = 192.0;
  static const setupTile = 96.0;
}

/// The pet, or its egg, painted and moving (spec §7.1, §7.3, §7.6).
///
/// It shows [look] as it is given and adds only what lives on screen: the
/// face's own movement, the blink, the idle moves, the hello, the tap hop and
/// the egg's wobble ([PetMotion]). None of that is saved or announced.
///
/// To a screen reader it is one item, read as [semanticLabel], that never
/// speaks on its own (§12): a run's line is spoken by whoever plays the run.
class PetView extends StatefulWidget {
  const PetView({
    super.key,
    required this.look,
    required this.spot,
    required this.semanticLabel,
    this.cues,
    this.beat,
    this.elapsed,
  });

  final PetLook look;

  /// The square the pet stands in, in points, standing on its bottom edge.
  final double spot;

  /// What the pet is: the pet's line or the egg's from the copy file.
  final String semanticLabel;

  /// Asks the pet for the hello (or, on the debug pet screen, any move).
  final PetCues? cues;

  /// The beat playing, if any. A new one starts the face's movement over, so
  /// the block-done beat bobs even over a running block's Pleased.
  final Object? beat;

  /// The time since the pet appeared. Only tests set it; the pet's own
  /// stopwatch is used otherwise, so it never reads the time of day.
  @visibleForTesting
  final Duration Function()? elapsed;

  @override
  State<PetView> createState() => _PetViewState();
}

class _PetViewState extends State<PetView> {
  final _clock = Stopwatch()..start();
  late PetMotion _motion;
  Timer? _timer;
  ValueListenable<TickerModeData>? _tickerMode;
  late final AppLifecycleListener _lifecycle;
  var _shown = true;

  Duration get _now => widget.elapsed?.call() ?? _clock.elapsed;

  @override
  void initState() {
    super.initState();
    _motion = PetMotion(widget.look, now: _now);
    widget.cues?.addListener(_cue);
    _lifecycle = AppLifecycleListener(
      onHide: () => _setShown(false),
      onShow: () => _setShown(true),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A screen under another, or a route on its way out, holds still.
    _tickerMode?.removeListener(_wake);
    _tickerMode = TickerMode.getValuesNotifier(context)..addListener(_wake);
    _wake();
  }

  @override
  void didUpdateWidget(PetView old) {
    super.didUpdateWidget(old);
    if (old.cues != widget.cues) {
      old.cues?.removeListener(_cue);
      widget.cues?.addListener(_cue);
    }
    if (old.look != widget.look) _motion.show(widget.look, _now);
    if (old.beat != widget.beat && widget.beat != null) _motion.restart(_now);
    _wake();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tickerMode?.removeListener(_wake);
    widget.cues?.removeListener(_cue);
    _lifecycle.dispose();
    super.dispose();
  }

  void _setShown(bool shown) {
    _shown = shown;
    _wake();
  }

  void _cue() {
    final act = widget.cues?._asked;
    if (act != null && _motion.play(act, _now)) _changed();
  }

  void _tap() {
    if (_motion.tap(_now)) _changed();
  }

  void _changed() {
    setState(() {});
    _wake();
  }

  /// Looks again when the picture next changes, if anyone can see it.
  void _wake() {
    _timer?.cancel();
    _timer = null;
    if (!_shown || !(_tickerMode?.value.enabled ?? true)) return;
    final wait = _motion.nextChange(_now) - _now;
    _timer = Timer(wait, () {
      if (!mounted) return;
      setState(() {});
      _wake();
    });
  }

  @override
  Widget build(BuildContext context) {
    final look = widget.look;
    final art = artOf(look.species);
    final now = _now;
    final rows = switch (look) {
      EggLook() => _eggRows(art, look.picture, _motion.eggShift(now)),
      HatchedLook() => _petRows(art, look.stage, _motion.pose(now)),
    };
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        child: SizedBox.square(
          dimension: widget.spot,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: PixelGrid.inSpot(
              spot: widget.spot,
              rows: rows,
              colours: _colours(look.species),
            ),
          ),
        ),
      ),
    );
  }
}

/// What a screen asks of the pets showing it. Each pet plays the move only if
/// it is resting and not already moving, as with a tap.
class PetCues extends ChangeNotifier {
  Act? _asked;

  /// The hello: call each time the app opens onto the pet (§7.6). Switching
  /// tabs is not opening, and a cold start routed to Focus has no hello; the
  /// screen decides.
  void hello() => play(Act.hop);

  /// Any move, now. For the debug pet screen.
  void play(Act act) {
    _asked = act;
    notifyListeners();
  }
}

/// The last picture composed for each stage and pose, so a frame that
/// changes nothing costs nothing.
final _petCache = <(SpeciesArt, int, Pose), List<String>>{};

List<String> _petRows(SpeciesArt art, int stage, Pose pose) {
  final key = (art, stage, pose);
  final rows = _petCache[key];
  if (rows != null) return rows;
  if (_petCache.length > 256) _petCache.clear();
  return _petCache[key] = composeStage(art, stage - 1, pose: pose);
}

List<String> _eggRows(SpeciesArt art, int picture, int shift) {
  final rows = gridRows(
    picture == 0 ? art.egg.whole : art.egg.cracks[picture - 1],
  );
  if (shift == 0) return rows;
  final clear = '.' * shift.abs();
  return [
    for (final row in rows)
      shift > 0
          ? clear + row.substring(0, row.length - shift)
          : row.substring(-shift) + clear,
  ];
}

final _colourCache = <Species, Map<String, Color>>{};

/// One colour set for both themes (spec §7.1).
Map<String, Color> _colours(Species species) => _colourCache.putIfAbsent(
  species,
  () => {
    for (final MapEntry(:key, :value) in artOf(species).colours.entries)
      key: Color(value),
  },
);

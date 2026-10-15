import 'package:flutter/widgets.dart';
import 'package:tomo_core/art/drawings.dart';
import 'package:tomo_core/focus/projection.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/pet/beat.dart';
import 'package:tomo_core/pet/pet_look.dart';
import 'package:tomo_core/pet/pet_motion.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/rewards/rewards.dart';

import '../app/tomo_look.dart';
import '../ui/buttons.dart';
import '../ui/motion.dart';
import '../ui/segmented.dart';
import '../ui/sharp_text.dart';
import '../ui/switch.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';
import 'pet_view.dart';

/// Every pet at every stage, and every egg picture, doing what the pet does
/// at each moment of the app, in either theme, with reduce motion and Calm pet
/// switchable (spec §7). The faces come from the real `look`; the movement is
/// the real [PetView]. A builder's tool for judging the pets by eye against
/// the Tomo Pet Art Review, not part of the product: its words are not in the
/// copy file and release builds never show it.
class PetGalleryScreen extends StatefulWidget {
  const PetGalleryScreen({super.key});

  @override
  State<PetGalleryScreen> createState() => _PetGalleryScreenState();
}

enum _Theme { phone, light, dark }

enum _Motion { phone, full, reduced }

enum _Pet { all, geode, joe, lily }

/// What is happening in the app, which the look turns into a face.
enum _Doing { nothing, block, onBreak, blockDone, levelUp }

enum _Spot { home, focus, setup }

class _PetGalleryScreenState extends State<PetGalleryScreen> {
  var _theme = _Theme.phone;
  var _motion = _Motion.phone;
  var _calm = false;
  var _pet = _Pet.all;
  var _doing = _Doing.nothing;
  var _spot = _Spot.focus;

  /// Counts the times a beat was started, so pressing it again replays it.
  var _beats = 0;

  final _cues = PetCues();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  @override
  void dispose() {
    _cues.dispose();
    // Leave the look as the kit gallery set it.
    super.dispose();
  }

  void _apply() {
    final now = lookOverride.value;
    lookOverride.value = LookOverride(
      theme: switch (_theme) {
        _Theme.phone => null,
        _Theme.light => ThemeName.light,
        _Theme.dark => ThemeName.dark,
      },
      pet: now.pet,
      textScale: now.textScale,
      reduceMotion: switch (_motion) {
        _Motion.phone => null,
        _Motion.full => false,
        _Motion.reduced => true,
      },
    );
  }

  void _set(VoidCallback change) {
    setState(change);
    _apply();
  }

  double get _spotSize => switch (_spot) {
    _Spot.home => PetSpot.home,
    _Spot.focus => PetSpot.focus,
    _Spot.setup => PetSpot.setupTile,
  };

  FocusState get _focus => switch (_doing) {
    _Doing.nothing || _Doing.blockDone || _Doing.levelUp => FocusState.idle,
    _Doing.block => FocusState.focusRunning,
    _Doing.onBreak => FocusState.breakRunning,
  };

  PendingBeats get _pending => switch (_doing) {
    _Doing.blockDone => const PendingBeats(
      playing: BlockCredited(minutes: 25, exp: 250),
    ),
    _Doing.levelUp => const PendingBeats(playing: LevelUp(level: 13)),
    _ => PendingBeats.none,
  };

  /// The pet at [stage], as the app would show it now.
  PetLook _hatched(BuildContext context, Species species, int stage) => look(
    LookState(
      species: species,
      exp: (stageStartLevels[stage - 1] - 1) * expPerLevel,
      hatched: true,
      focus: _focus,
      calmPet: _calm,
      reduceMotion: reduceMotion(context),
      now: DateTime.utc(2026),
    ),
    _pending,
  );

  /// The egg showing [picture]. Only the whole egg can be waiting; the
  /// cracks show during a block.
  PetLook _egg(BuildContext context, Species species, int picture) {
    final waiting = look(
      LookState(
        species: species,
        exp: 0,
        hatched: false,
        focus: picture == 0 ? _focus : FocusState.focusRunning,
        calmPet: _calm,
        reduceMotion: reduceMotion(context),
        now: DateTime.utc(2026),
      ),
      PendingBeats.none,
    );
    return EggLook(
      species: species,
      movement: waiting.movement,
      picture: picture,
      mayWobble: (waiting as EggLook).mayWobble,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);

    Widget gap([num n = 4]) => SizedBox(height: u(n), width: u(n));

    Widget label(String words) =>
        PixelText(words, step: TypeStep.caption, colour: colours.muted);

    Widget choice<T>(
      String title,
      List<T> values,
      String Function(T) name,
      T selected,
      ValueChanged<T> onChanged,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        label(title),
        gap(1),
        PixelSegmented<T>(
          segments: [for (final v in values) Segment(v, name(v))],
          selected: selected,
          onChanged: onChanged,
        ),
      ],
    );

    Widget pet(PetLook look, String caption) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PetView(
          look: look,
          spot: _spotSize,
          semanticLabel: caption,
          cues: _cues,
          beat: _doing == _Doing.blockDone || _doing == _Doing.levelUp
              ? _beats
              : null,
        ),
        gap(1),
        label(caption),
      ],
    );

    Widget wrap(List<Widget> children, {num spacing = 6}) => Wrap(
      spacing: u(spacing),
      runSpacing: u(6),
      crossAxisAlignment: WrapCrossAlignment.end,
      children: children,
    );

    final doing = choice(
      'What is happening',
      _Doing.values,
      (d) => _doingNames[d]!,
      _doing,
      (v) => setState(() {
        _doing = v;
        _beats++;
      }),
    );

    final play = [
      for (final act in Act.values)
        PixelButton(
          label: _actNames[act]!,
          kind: ButtonKind.secondary,
          onPressed: () => _cues.play(act),
        ),
      if (_doing == _Doing.blockDone || _doing == _Doing.levelUp)
        PixelButton(
          label: 'Beat again',
          kind: ButtonKind.secondary,
          onPressed: () => setState(() => _beats++),
        ),
    ];

    final species = switch (_pet) {
      _Pet.all => Species.values,
      _Pet.geode => [Species.geode],
      _Pet.joe => [Species.joe],
      _Pet.lily => [Species.lily],
    };

    final face = switch (_hatched(context, Species.geode, 1)) {
      HatchedLook(:final face) => face.name,
      EggLook() => '',
    };

    final bar = ColoredBox(
      color: colours.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(u(12), u(4), u(12), u(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            doing,
            gap(3),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (i, button) in play.indexed) ...[
                    if (i > 0) gap(3),
                    button,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final scroll = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(u(12), u(8), u(12), u(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PixelText('Pet gallery', step: TypeStep.petName),
          label(
            'The real look and the real pet widget. Compare with the Tomo '
            'Pet Art Review.',
          ),
          gap(6),
          choice(
            'Theme',
            _Theme.values,
            (t) => _themeNames[t]!,
            _theme,
            (v) => _set(() => _theme = v),
          ),
          gap(4),
          choice(
            'Reduce motion',
            _Motion.values,
            (m) => _motionNames[m]!,
            _motion,
            (v) => _set(() => _motion = v),
          ),
          gap(4),
          PixelSwitchRow(
            title: 'Calm pet',
            subtitle: 'Resting, Pleased and Drowsy become Still',
            value: _calm,
            onChanged: (v) => setState(() => _calm = v),
          ),
          gap(4),
          doing,
          label('Face: $face'),
          gap(4),
          label(
            'Play now (only the resting pet plays these; the egg wobbles '
            'when tapped)',
          ),
          gap(1),
          wrap(play),
          gap(4),
          choice(
            'Pet',
            _Pet.values,
            (p) => _petNames[p]!,
            _pet,
            (v) => setState(() => _pet = v),
          ),
          gap(4),
          choice(
            'Spot',
            _Spot.values,
            (s) => _spotNames[s]!,
            _spot,
            (v) => setState(() => _spot = v),
          ),
          for (final s in species) ...[
            gap(16),
            PixelText(artOf(s).name, step: TypeStep.title),
            gap(4),
            wrap(spacing: 2, [
              for (var stage = 1; stage <= 4; stage++)
                pet(_hatched(context, s, stage), 'Stage $stage'),
            ]),
            gap(6),
            wrap(spacing: 2, [
              for (var i = 0; i < eggPictureCount(s); i++)
                pet(_egg(context, s, i), i == 0 ? 'Egg' : 'Crack $i'),
            ]),
          ],
        ],
      ),
    );

    return SafeArea(
      child: Column(
        children: [
          Expanded(child: scroll),
          bar,
        ],
      ),
    );
  }
}

const _themeNames = {
  _Theme.phone: 'Phone',
  _Theme.light: 'Light',
  _Theme.dark: 'Dark',
};

const _motionNames = {
  _Motion.phone: 'Phone',
  _Motion.full: 'Off',
  _Motion.reduced: 'On',
};

const _petNames = {
  _Pet.all: 'All',
  _Pet.geode: 'Geode',
  _Pet.joe: 'Joe',
  _Pet.lily: 'Lily',
};

const _doingNames = {
  _Doing.nothing: 'Rest',
  _Doing.block: 'Block',
  _Doing.onBreak: 'Break',
  _Doing.blockDone: 'Done',
  _Doing.levelUp: 'Level',
};

const _spotNames = {
  _Spot.home: 'Home 192',
  _Spot.focus: 'Focus 168',
  _Spot.setup: 'Setup 96',
};

const _actNames = {
  Act.hop: 'Hello',
  Act.glance: 'Glance',
  Act.lookUp: 'Look up',
  Act.doubleBlink: 'Blink ×2',
  Act.twitch: 'Twitch',
  Act.wiggle: 'Wiggle',
};

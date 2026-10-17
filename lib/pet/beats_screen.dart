import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:tomo_core/art/drawings.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/pet/beat.dart';
import 'package:tomo_core/pet/pet_look.dart';
import 'package:tomo_core/pet/run_script.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/rewards/rewards.dart';

import '../app/tomo_look.dart';
import '../l10n/app_localizations.dart';
import '../platform/haptics.dart';
import '../ui/buttons.dart';
import '../ui/motion.dart';
import '../ui/pixel_box.dart';
import '../ui/pixel_icon.dart';
import '../ui/segmented.dart';
import '../ui/sharp_text.dart';
import '../ui/switch.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';
import 'pet_view.dart';
import 'reward_view.dart';
import 'run_player.dart';

/// Every beat and the common stacked runs (spec §7.5, ADR-0019), for each
/// pet and stage, in either theme, full and reduced, played by the real run
/// player on a stand-in of Focus. A tap on the stand-in skips, as on Focus.
/// A builder's tool for judging the celebrations by eye against Pixel reward
/// effects and Tomo Pixel Screens: its words are not in the copy file and
/// release builds never show it.
class BeatsScreen extends StatefulWidget {
  const BeatsScreen({super.key});

  @override
  State<BeatsScreen> createState() => _BeatsScreenState();
}

enum _Theme { phone, light, dark }

enum _Motion { phone, full, reduced }

/// What earns the run: a finished block, or a task marked done.
enum _From { block, task }

/// What the run reaches after its first beat.
enum _Then { nothing, level, evolution, hatch }

class _BeatsScreenState extends State<BeatsScreen>
    with TickerProviderStateMixin {
  var _theme = _Theme.phone;
  var _motion = _Motion.phone;
  var _from = _From.block;
  var _then = _Then.level;
  var _species = Species.geode;
  var _stage = 1;
  var _slow = false;
  var _repeat = true;

  RunPlayer? _player;
  Timer? _again;

  /// What the stand-in last said happened: finished or skipped.
  String _ended = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apply();
      _play();
    });
  }

  @override
  void dispose() {
    _again?.cancel();
    _player?.dispose();
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

  /// Changes a switch and plays the run again with it, once the look has
  /// caught up.
  void _set(VoidCallback change) {
    setState(change);
    _apply();
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  /// The stage the evolution grows from: 1 to 3.
  int get _grows => _stage.clamp(1, 3);

  /// The run, and the EXP before it, chosen so its numbers come out right:
  /// a level inside the chosen stage, or one just short of the next.
  (List<Beat>, int) get _chosen {
    final task = _from == _From.task;
    final Beat first = task
        ? const TaskCompleted(bonusExp: 100)
        : const BlockCredited(minutes: 25, exp: 250);
    final grant = task ? 100 : 250;
    final inStage = (stageStartLevels[_stage - 1] + 1) * expPerLevel;
    final nextStage = (stageStartLevels[_grows] - 1) * expPerLevel;
    return switch (_then) {
      _Then.nothing => ([first], inStage + 100),
      _Then.level => (
        [first, LevelUp(level: levelForExp(inStage + 550 + grant))],
        inStage + 550,
      ),
      _Then.evolution => (
        [
          first,
          LevelUp(level: stageStartLevels[_grows]),
          Evolution(from: _grows, to: _grows + 1),
        ],
        nextStage - 50,
      ),
      // Only the first block hatches the egg.
      _Then.hatch => (
        [const BlockCredited(minutes: 15, exp: 150), Hatch(species: _species)],
        0,
      ),
    };
  }

  void _play() {
    if (!mounted) return;
    _again?.cancel();
    _player?.dispose();
    final (run, expBefore) = _chosen;
    final player = RunPlayer(
      script: RunScript(
        run,
        species: _species,
        expBefore: expBefore,
        theme: TomoTheme.of(context).palette.theme,
        movement: reduceMotion(context) ? Movement.reduced : Movement.full,
      ),
      vsync: this,
      haptics: const SystemHaptics(),
      speed: _slow ? 0.25 : 1,
      onEnd: (end) => setState(() => _ended = end.name),
    );
    player.addListener(() {
      if (_repeat && !player.playing && _again == null) {
        _again = Timer(const Duration(milliseconds: 1400), () {
          _again = null;
          _play();
        });
      }
    });
    setState(() {
      _player = player;
      _ended = '';
    });
    player.start();
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

    final controls = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(u(12), u(6), u(12), u(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PixelText('Beats', step: TypeStep.title),
          label(
            'The real run player on a stand-in of Focus. Tap it to skip. '
            'Compare with Pixel reward effects and Tomo Pixel Screens.',
          ),
          gap(4),
          choice(
            'From',
            _From.values,
            (f) => _fromNames[f]!,
            _then == _Then.hatch ? _From.block : _from,
            (v) => _set(() {
              _from = v;
              if (v == _From.task && _then == _Then.hatch) _then = _Then.level;
            }),
          ),
          gap(3),
          choice(
            'Then',
            _Then.values,
            (t) => _thenNames[t]!,
            _then,
            (v) => _set(() => _then = v),
          ),
          gap(3),
          choice(
            'Pet',
            Species.values,
            (s) => artOf(s).name,
            _species,
            (v) => _set(() => _species = v),
          ),
          gap(3),
          choice(
            _then == _Then.evolution ? 'Stage (grows from 1 to 3)' : 'Stage',
            const [1, 2, 3, 4],
            (s) => '$s',
            _stage,
            (v) => _set(() => _stage = v),
          ),
          gap(3),
          choice(
            'Theme',
            _Theme.values,
            (t) => _themeNames[t]!,
            _theme,
            (v) => _set(() => _theme = v),
          ),
          gap(3),
          choice(
            'Reduce motion',
            _Motion.values,
            (m) => _motionNames[m]!,
            _motion,
            (v) => _set(() => _motion = v),
          ),
          gap(3),
          PixelSwitchRow(
            title: 'Quarter speed',
            subtitle: 'See every pixel step',
            value: _slow,
            onChanged: (v) => _set(() => _slow = v),
          ),
          PixelSwitchRow(
            title: 'Repeat',
            subtitle: 'Play again 1.4 s after it falls still',
            value: _repeat,
            onChanged: (v) => _set(() => _repeat = v),
          ),
          gap(3),
          PixelButton(
            label: 'Play again',
            kind: ButtonKind.secondary,
            wide: true,
            onPressed: _play,
          ),
          if (_ended.isNotEmpty) ...[gap(2), label('The run said: $_ended')],
        ],
      ),
    );

    final player = _player;
    return SafeArea(
      child: Column(
        children: [
          Flexible(child: controls),
          ColoredBox(
            color: colours.sunken,
            child: SizedBox(height: u(1)),
          ),
          Expanded(
            flex: 2,
            child: player == null
                ? const SizedBox.expand()
                : ClipRect(
                    child: ListenableBuilder(
                      listenable: player,
                      builder: (context, _) => _Stand(
                        player: player,
                        species: _species,
                        stage: _stage,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// A stand-in of Focus after a block (Tomo Pixel Screens): the header, the
/// pet, its line, the EXP bar and the choices, or the hatch takeover once the
/// hatch has cleared the screen.
class _Stand extends StatelessWidget {
  const _Stand({
    required this.player,
    required this.species,
    required this.stage,
  });

  final RunPlayer player;
  final Species species;
  final int stage;

  @override
  Widget build(BuildContext context) {
    final frame = player.frame;
    final theme = TomoTheme.of(context);
    // The accent is the egg's grey until the hatch's burst brings the pet's.
    return TomoTheme(
      colours: TomoColours.of(
        theme.palette.theme,
        frame.hatched ? species : null,
      ),
      child: ColoredBox(
        color: theme.ground,
        child: SkipRun(
          player: player,
          child: frame.cleared ? _hatch(context) : _focus(context),
        ),
      ),
    );
  }

  PetLook _rest(BuildContext context, {required int stage}) => HatchedLook(
    species: species,
    movement: reduceMotion(context) ? Movement.reduced : Movement.full,
    stage: stage,
    face: Face.resting,
  );

  int get _finalStage {
    final run = player.script.run;
    for (final beat in run.reversed) {
      if (beat is Evolution) return beat.to;
      if (beat is Hatch) return 1;
    }
    return stageForExp(player.script.expBefore);
  }

  Widget _focus(BuildContext context) {
    final frame = player.frame;
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final words = AppLocalizations.of(context);
    final payload = frame.payload;
    return Padding(
      padding: EdgeInsets.fromLTRB(u(12), u(6), u(12), u(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DitherOver(
            active: frame.dither,
            child: Row(
              children: [
                SizedBox.square(
                  dimension: u.target,
                  child: Center(
                    child: PixelIcon(IconName.down, colour: colours.ink),
                  ),
                ),
                gapW(u, 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PixelText('Write the intro', step: TypeStep.title),
                      PixelText(
                        'Thesis',
                        step: TypeStep.caption,
                        colour: colours.muted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: u(6)),
          Center(
            child: RewardPet(
              frame: frame,
              rest: _rest(context, stage: _finalStage),
              spot: PetSpot.focus,
              semanticLabel: 'The pet',
            ),
          ),
          SizedBox(height: u(6)),
          PixelText(_lines[species]!, textAlign: TextAlign.center),
          SizedBox(height: u(6)),
          RewardBar(
            bar: frame.bar,
            plate: frame.plate,
            caption: Row(
              children: [
                PixelText.number(
                  words.levelChip(frame.level),
                  step: TypeStep.caption,
                  colour: colours.muted,
                ),
              ],
            ),
          ),
          const Spacer(),
          _steppingIn(
            context,
            payload,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PixelButton(label: 'Take a 5-min break', onPressed: () {}),
                SizedBox(height: u(5)),
                PixelButton(
                  label: 'Another 25-min block',
                  kind: ButtonKind.secondary,
                  onPressed: () {},
                ),
                SizedBox(height: u(5)),
                PixelButton(
                  label: 'Mark task done',
                  kind: ButtonKind.quiet,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hatch(BuildContext context) {
    final frame = player.frame;
    final u = UiPixel.of(context);
    final payload = frame.payload;
    return Padding(
      padding: EdgeInsets.fromLTRB(u(12), u(6), u(12), u(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Center(
            child: RewardPet(
              frame: frame,
              rest: _rest(context, stage: 1),
              spot: PetSpot.hatch,
              semanticLabel: 'The pet',
            ),
          ),
          SizedBox(height: u(6)),
          _steppingIn(
            context,
            payload,
            const PixelText('(the hatch line)', textAlign: TextAlign.center),
          ),
          const Spacer(),
          _steppingIn(
            context,
            payload,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PixelBox(
                  fill: TomoTheme.of(context).surface,
                  outline: TomoTheme.of(context).boundary,
                  child: Padding(
                    padding: EdgeInsets.all(u(7)),
                    child: PixelText(artOf(species).name),
                  ),
                ),
                SizedBox(height: u(5)),
                PixelButton(label: 'Done', onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// [child] hidden until [payload] steps it in, its room kept.
  Widget _steppingIn(BuildContext context, StepIn? payload, Widget child) {
    final u = UiPixel.of(context);
    return Visibility.maintain(
      visible: payload != null,
      child: Transform.translate(
        offset: Offset(0, u(payload?.dy ?? 0)),
        child: Opacity(opacity: payload?.opacity ?? 0, child: child),
      ),
    );
  }

  static Widget gapW(UiPixel u, num n) => SizedBox(width: u(n));
}

/// Stand-in lines, as the effects prototype had them; Focus says the real
/// ones.
const _lines = {
  Species.geode: 'Solid work.',
  Species.joe: 'Nice one!',
  Species.lily: 'That felt good.',
};

const _fromNames = {_From.block: 'Block', _From.task: 'Task'};

const _thenNames = {
  _Then.nothing: 'Nothing',
  _Then.level: 'Level',
  _Then.evolution: 'Evolve',
  _Then.hatch: 'Hatch',
};

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

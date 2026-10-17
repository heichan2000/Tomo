import 'package:flutter/widgets.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/tasks/task_status.dart';

import '../app/tomo_look.dart';
import '../pet/beats_screen.dart';
import '../pet/pet_gallery_screen.dart';
import 'buttons.dart';
import 'exp_bar.dart';
import 'motion.dart';
import 'pixel_box.dart';
import 'pixel_check_screen.dart';
import 'pixel_icon.dart';
import 'rows.dart';
import 'segmented.dart';
import 'sharp_text.dart';
import 'sheet.dart';
import 'switch.dart';
import 'text_field.dart';
import 'tomo_theme.dart';
import 'ui_pixel.dart';

/// Every part of the pixel kit (spec §9.1–§9.5) in every state, switchable
/// between the themes, the three accents and the neutral one, text sizes up
/// to 200% and reduced motion. A builder's tool for judging the kit by eye,
/// not part of the product: its words are not in the copy file and release
/// builds never show it.
class KitGalleryScreen extends StatefulWidget {
  const KitGalleryScreen({super.key});

  @override
  State<KitGalleryScreen> createState() => _KitGalleryScreenState();
}

/// The gallery's switches: null follows the phone (or the app).
enum _Theme { phone, light, dark }

enum _Pet { app, egg, geode, joe, lily }

enum _Text { phone, p100, p130, p150, p200 }

enum _Motion { phone, full, reduced }

class _KitGalleryScreenState extends State<KitGalleryScreen> {
  var _theme = _Theme.phone;
  var _pet = _Pet.geode;
  var _text = _Text.phone;
  var _motion = _Motion.phone;

  // The live parts' own state.
  final _empty = TextEditingController();
  final _filled = TextEditingController(text: 'Thesis');
  final _long = TextEditingController(
    text:
        'Read the Kowalski paper and write down the three questions it '
        'leaves open',
  );
  var _appearance = 'Match phone';
  var _status = TaskStatus.doing;
  var _length = '25 min';
  var _calm = false;
  var _autoStart = true;
  var _lit = 8;

  @override
  void initState() {
    super.initState();
    // The look sits above the navigator, so it can't change mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  @override
  void dispose() {
    _empty.dispose();
    _filled.dispose();
    _long.dispose();
    super.dispose();
  }

  void _apply() {
    lookOverride.value = LookOverride(
      theme: switch (_theme) {
        _Theme.phone => null,
        _Theme.light => ThemeName.light,
        _Theme.dark => ThemeName.dark,
      },
      pet: switch (_pet) {
        _Pet.app => null,
        _Pet.egg => (species: null),
        _Pet.geode => (species: Species.geode),
        _Pet.joe => (species: Species.joe),
        _Pet.lily => (species: Species.lily),
      },
      textScale: switch (_text) {
        _Text.phone => null,
        _Text.p100 => 1,
        _Text.p130 => 1.3,
        _Text.p150 => 1.5,
        _Text.p200 => 2,
      },
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

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);

    Widget gap([num n = 4]) => SizedBox(height: u(n), width: u(n));

    Widget section(String title, List<Widget> parts, {String? note}) => Padding(
      padding: EdgeInsets.only(top: u(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PixelText(title, step: TypeStep.title),
          if (note != null)
            PixelText(note, step: TypeStep.caption, colour: colours.muted),
          gap(6),
          for (final (i, part) in parts.indexed) ...[if (i > 0) gap(6), part],
        ],
      ),
    );

    Widget label(String words) =>
        PixelText(words, step: TypeStep.caption, colour: colours.muted);

    Widget labelled(String words, Widget part) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [part, gap(1), label(words)],
    );

    Widget wrap(List<Widget> children) => Wrap(
      spacing: u(6),
      runSpacing: u(6),
      crossAxisAlignment: WrapCrossAlignment.end,
      children: children,
    );

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

    final dpr = u.devicePixelRatio;
    final screen = MediaQuery.sizeOf(context) * dpr;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(u(12), u(8), u(12), u(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PixelText('Kit gallery', step: TypeStep.petName),
            label(
              '${_number(dpr)}× · ${screen.width.round()} × '
              '${screen.height.round()} dots · UI pixel ${u.dots} dots · '
              'body ${dotsAt(context, TypeStep.body)} dots per font pixel',
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
              'Accent',
              _Pet.values,
              (p) => _petNames[p]!,
              _pet,
              (v) => _set(() => _pet = v),
            ),
            gap(4),
            choice(
              'Text size',
              _Text.values,
              (t) => _textNames[t]!,
              _text,
              (v) => _set(() => _text = v),
            ),
            gap(4),
            choice(
              'Motion',
              _Motion.values,
              (m) => _motionNames[m]!,
              _motion,
              (v) => _set(() => _motion = v),
            ),
            gap(4),
            PixelButton(
              label: 'Pixel check screen',
              kind: ButtonKind.secondary,
              wide: true,
              onPressed: () => Navigator.of(context).push(
                PixelPageRoute<void>(builder: (_) => const PixelCheckScreen()),
              ),
            ),
            gap(4),
            PixelButton(
              label: 'Pet gallery',
              kind: ButtonKind.secondary,
              wide: true,
              onPressed: () => Navigator.of(context).push(
                PixelPageRoute<void>(builder: (_) => const PetGalleryScreen()),
              ),
            ),
            gap(4),
            PixelButton(
              label: 'Beats',
              kind: ButtonKind.secondary,
              wide: true,
              onPressed: () => Navigator.of(
                context,
              ).push(PixelPageRoute<void>(builder: (_) => const BeatsScreen())),
            ),

            section('Colours', [
              wrap([
                for (final (name, colour) in [
                  ('ground', colours.ground),
                  ('surface', colours.surface),
                  ('sunken', colours.sunken),
                  ('ink', colours.ink),
                  ('muted', colours.muted),
                  ('boundary', colours.boundary),
                  ('destructive', colours.destructive),
                  ('accent', colours.accent),
                  ('on accent', colours.onAccent),
                ])
                  labelled(
                    name,
                    PixelBox(
                      fill: colour,
                      // The ground swatch would vanish on the ground.
                      outline: colour == colours.ground
                          ? colours.boundary
                          : null,
                      child: SizedBox.square(dimension: u(16)),
                    ),
                  ),
              ]),
            ], note: 'Shapes stand apart by shade only. No status colours.'),

            section('Type', [
              for (final step in TypeStep.values)
                labelled(
                  '${step.name} · ${dotsAt(context, step)} dots per font '
                  'pixel',
                  PixelText(_samples[step]!, step: step),
                ),
              labelled(
                'a number: stops at 130%, never wraps',
                const PixelText.number('480 / 600 EXP'),
              ),
              labelled(
                'a number in a narrow spot steps down to fit',
                SizedBox(
                  width: u(48),
                  child: const PixelText.number(
                    '12:45:30',
                    step: TypeStep.title,
                  ),
                ),
              ),
              labelled(
                'centred: every line starts on a whole dot',
                const PixelText(
                  'Hatches when you finish a focus block. Each line of this '
                  'is centred on its own.',
                  textAlign: TextAlign.center,
                ),
              ),
            ]),

            section(
              'Buttons',
              [
                for (final kind in ButtonKind.values)
                  wrap([
                    for (final held in HeldState.values)
                      labelled(
                        '${kind.name} · ${held == HeldState.live ? 'live' : held.name}',
                        PixelButton(
                          label: _buttonLabels[kind]!,
                          kind: kind,
                          held: held,
                          onPressed: () {},
                        ),
                      ),
                    labelled(
                      '${kind.name} · turned off',
                      PixelButton(
                        label: _buttonLabels[kind]!,
                        kind: kind,
                        onPressed: null,
                      ),
                    ),
                  ]),
                labelled(
                  'wide',
                  PixelButton(
                    label: 'Start focusing',
                    wide: true,
                    onPressed: () {},
                  ),
                ),
              ],
              note:
                  'At least 48 pt. Pressed: one shade toward ink. Turned '
                  'off: solid sunken. Keyboard focus: a ring with a gap.',
            ),

            section('Icon buttons', [
              wrap([
                for (final held in HeldState.values)
                  labelled(
                    held == HeldState.live ? 'live' : held.name,
                    PixelIconButton(
                      icon: const PixelIcon(IconName.gear),
                      semanticLabel: 'Settings',
                      held: held,
                      onPressed: () {},
                    ),
                  ),
                for (final name in [
                  IconName.back,
                  IconName.more,
                  IconName.plus,
                  IconName.minus,
                  IconName.close,
                ])
                  labelled(
                    name.name,
                    PixelIconButton(
                      icon: PixelIcon(name),
                      semanticLabel: name.name,
                      onPressed: () {},
                    ),
                  ),
              ]),
            ]),

            section('Text fields', [
              labelled(
                'empty, with a hint',
                PixelTextField(controller: _empty, hint: 'Project name'),
              ),
              labelled('filled', PixelTextField(controller: _filled)),
              labelled(
                'long text wraps and the field grows',
                PixelTextField(controller: _long),
              ),
            ], note: 'Tap one: the outline turns into two pixels of accent.'),

            section('Choices', [
              choice(
                'Appearance',
                ['Match phone', 'Light', 'Dark'],
                (s) => s,
                _appearance,
                (v) => setState(() => _appearance = v),
              ),
              choice(
                'Status',
                TaskStatus.values,
                (s) => _statusNames[s]!,
                _status,
                (v) => setState(() => _status = v),
              ),
              choice(
                'Labels too long for one row stack instead',
                ['25 min', '50 min', 'Custom length, set by you'],
                (s) => s,
                _length,
                (v) => setState(() => _length = v),
              ),
            ]),

            section('Switches', [
              wrap([
                labelled(
                  'off',
                  PixelSwitch(
                    value: false,
                    semanticLabel: 'Off',
                    onChanged: (_) {},
                  ),
                ),
                labelled(
                  'live',
                  PixelSwitch(
                    value: _autoStart,
                    semanticLabel: 'Auto-start',
                    onChanged: (v) => setState(() => _autoStart = v),
                  ),
                ),
                labelled(
                  'pressed',
                  PixelSwitch(
                    value: true,
                    semanticLabel: 'Pressed',
                    held: HeldState.pressed,
                    onChanged: (_) {},
                  ),
                ),
                labelled(
                  'focused',
                  PixelSwitch(
                    value: false,
                    semanticLabel: 'Focused',
                    held: HeldState.focused,
                    onChanged: (_) {},
                  ),
                ),
                labelled(
                  'turned off',
                  const PixelSwitch(
                    value: false,
                    semanticLabel: 'Turned off',
                    onChanged: null,
                  ),
                ),
              ]),
              PixelSwitchRow(
                title: 'Calm pet',
                subtitle: 'Your pet stays still',
                value: _calm,
                onChanged: (v) => setState(() => _calm = v),
              ),
            ], note: 'The knob slides ten UI pixels in 120 ms.'),

            section('EXP bar', [
              for (final lit in [0, 8, 20])
                labelled('$lit of 20 lit', ExpBar(lit: lit)),
              labelled(
                'tap the buttons: the bar jumps (the fill is the reward '
                'effects\' to design)',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExpBar(lit: _lit),
                    gap(3),
                    PixelText.number(
                      '${_lit * 30} / 600 EXP',
                      colour: colours.muted,
                    ),
                    gap(3),
                    wrap([
                      PixelIconButton(
                        icon: const PixelIcon(IconName.minus),
                        semanticLabel: 'One block fewer',
                        onPressed: _lit > 0
                            ? () => setState(() => _lit--)
                            : null,
                      ),
                      PixelIconButton(
                        icon: const PixelIcon(IconName.plus),
                        semanticLabel: 'One block more',
                        onPressed: _lit < 20
                            ? () => setState(() => _lit++)
                            : null,
                      ),
                    ]),
                  ],
                ),
              ),
            ]),

            section('Task rows', [
              for (final (status, title, meta) in [
                (TaskStatus.doing, 'Write the intro', '2 of 4 blocks'),
                (TaskStatus.todo, 'Email Łukasz about the draft', '1 block'),
                (TaskStatus.done, 'Outline chapter 1', '3 blocks'),
              ])
                PixelRow(
                  title: title,
                  subtitle: meta,
                  mutedTitle: status == TaskStatus.done,
                  onTap: () {},
                  leading: PixelIconButton(
                    icon: StatusGlyph(status),
                    semanticLabel: _statusNames[status]!,
                    onPressed: () {},
                  ),
                  trailing: [
                    if (status == TaskStatus.doing) const PixelChip('Doing'),
                    PixelIconButton(
                      icon: PixelIcon(IconName.more, colour: colours.muted),
                      semanticLabel: 'More',
                      onPressed: () {},
                    ),
                  ],
                ),
              labelled(
                'pressed',
                PixelRow(
                  title: 'Read the Kowalski paper',
                  subtitle: 'No blocks yet',
                  held: HeldState.pressed,
                  onTap: () {},
                ),
              ),
            ], note: 'Doing first, then to do, done at the bottom.'),

            section('Status glyphs and chips', [
              wrap([
                for (final status in TaskStatus.values)
                  labelled(_statusNames[status]!, StatusGlyph(status)),
              ]),
              wrap([
                const PixelChip('Doing'),
                const PixelChip('Focus', tone: ChipTone.accent),
                const PixelChip('Break', tone: ChipTone.muted),
              ]),
            ]),

            section('Icons', [
              for (final (name, colour) in [
                ('ink', colours.ink),
                ('muted', colours.muted),
                ('accent', colours.accent),
              ])
                labelled(
                  name,
                  wrap([
                    for (final icon in IconName.values)
                      PixelIcon(icon, colour: colour),
                  ]),
                ),
              labelled(
                'on accent',
                PixelBox(
                  fill: colours.accent,
                  child: Padding(
                    padding: EdgeInsets.all(u(4)),
                    child: wrap([
                      for (final icon in IconName.values)
                        PixelIcon(icon, colour: colours.onAccent),
                    ]),
                  ),
                ),
              ),
            ], note: '12 × 12, one UI pixel per icon pixel.'),

            section(
              'Sheets',
              [
                PixelButton(
                  label: 'Stop this block?',
                  kind: ButtonKind.secondary,
                  wide: true,
                  onPressed: () => showPixelSheet<void>(context, _stopSheet),
                ),
                PixelButton(
                  label: 'New project (a field)',
                  kind: ButtonKind.secondary,
                  wide: true,
                  onPressed: () => showPixelSheet<void>(context, _projectSheet),
                ),
                PixelButton(
                  label: 'A long sheet that scrolls',
                  kind: ButtonKind.secondary,
                  wide: true,
                  onPressed: () => showPixelSheet<void>(context, _longSheet),
                ),
              ],
              note:
                  'Over the dither; slides 24 pt in whole UI pixels, or '
                  'cross-fades under reduced motion.',
            ),

            section('Routes', [
              PixelButton(
                label: 'Push a screen',
                kind: ButtonKind.secondary,
                wide: true,
                onPressed: () => Navigator.of(context).push(
                  PixelPageRoute<void>(builder: (_) => const _PushedScreen()),
                ),
              ),
              PixelButton(
                label: 'Open a takeover from below',
                kind: ButtonKind.secondary,
                wide: true,
                onPressed: () => Navigator.of(context).push(
                  PixelPageRoute<void>(
                    from: AxisDirection.down,
                    builder: (_) => const _PushedScreen(),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _stopSheet(BuildContext context) {
    final u = UiPixel.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PixelText('Stop this block?', step: TypeStep.title),
        SizedBox(height: u(5)),
        const PixelText(
          'Only finished blocks count, so this one won’t. Everything you’ve '
          'finished before stays.',
        ),
        SizedBox(height: u(9)),
        PixelButton(
          label: 'Keep going',
          wide: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        // Eight UI pixels apart, at least 12 pt (spec §8.6).
        SizedBox(height: u(8)),
        PixelButton(
          label: 'Stop early',
          kind: ButtonKind.destructive,
          wide: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _projectSheet(BuildContext context) => _ProjectSheet();

  Widget _longSheet(BuildContext context) {
    final u = UiPixel.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PixelText('Move to project', step: TypeStep.title),
        for (var i = 1; i <= 16; i++) ...[
          SizedBox(height: u(3)),
          PixelRow(
            title: 'Project $i',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ],
    );
  }
}

class _ProjectSheet extends StatefulWidget {
  @override
  State<_ProjectSheet> createState() => _ProjectSheetState();
}

class _ProjectSheetState extends State<_ProjectSheet> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = UiPixel.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PixelText('New project', step: TypeStep.title),
        SizedBox(height: u(5)),
        PixelTextField(
          controller: _name,
          hint: 'Project name',
          autofocus: true,
          maxLines: 1,
          onSubmitted: (_) => Navigator.of(context).pop(),
        ),
        SizedBox(height: u(8)),
        PixelButton(
          label: 'Create',
          wide: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _PushedScreen extends StatelessWidget {
  const _PushedScreen();

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return ColoredBox(
      color: colours.ground,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: u(6)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PixelIconButton(
                    icon: const PixelIcon(IconName.back),
                    semanticLabel: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: PixelText('Pushed screen', step: TypeStep.title),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(u(6)),
                child: PixelText(
                  'It slid in by 24 pt in whole UI pixels; nothing behind it '
                  'moved.',
                  colour: colours.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _themeNames = {
  _Theme.phone: 'Phone',
  _Theme.light: 'Light',
  _Theme.dark: 'Dark',
};

const _petNames = {
  _Pet.app: 'App',
  _Pet.egg: 'Egg',
  _Pet.geode: 'Geode',
  _Pet.joe: 'Joe',
  _Pet.lily: 'Lily',
};

const _textNames = {
  _Text.phone: 'Phone',
  _Text.p100: '100%',
  _Text.p130: '130%',
  _Text.p150: '150%',
  _Text.p200: '200%',
};

const _motionNames = {
  _Motion.phone: 'Phone',
  _Motion.full: 'Full',
  _Motion.reduced: 'Reduced',
};

const _statusNames = {
  TaskStatus.todo: 'To do',
  TaskStatus.doing: 'Doing',
  TaskStatus.done: 'Done',
};

const _buttonLabels = {
  ButtonKind.primary: 'Start focusing',
  ButtonKind.secondary: 'Not now',
  ButtonKind.quiet: 'Skip break',
  ButtonKind.quietMuted: 'Stop early',
  ButtonKind.quietDestructive: 'Delete task',
  ButtonKind.destructive: 'Stop early',
};

const _samples = {
  TypeStep.caption: 'About 19 min left · 2 of 4 blocks',
  TypeStep.body:
      'The quick brown fox jumps over the lazy dog. 0123456789 '
      '“Quotes”, it’s — dashes… Łukasz, Zoë.',
  TypeStep.title: 'Stop this block?',
  TypeStep.petName: 'Geode',
};

String _number(double value) =>
    value == value.roundToDouble() ? '${value.round()}' : '$value';

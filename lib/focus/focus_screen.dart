import 'dart:async';

import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/focus/block_lengths.dart';
import 'package:tomo_core/result.dart';

import '../app/providers.dart';
import '../l10n/app_localizations.dart';
import '../pet/pet_label.dart';
import '../pet/pet_view.dart';
import '../platform/notifications.dart';
import '../ui/buttons.dart';
import '../ui/pixel_box.dart';
import '../ui/pixel_icon.dart';
import '../ui/screen_body.dart';
import '../ui/segmented.dart';
import '../ui/sharp_text.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';
import 'length_sheet.dart';
import 'live_focus.dart';
import 'task_picker.dart';

/// Focus (spec §8.4), a takeover above the shell with the tab bar hidden.
///
/// With [ready], a task picked and no cycle yet, it is **Ready**. Once a
/// block starts, or when it opens on a live cycle, it is [LiveFocus], until
/// *Start another task* brings it back to Ready on the task picked.
class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key, this.ready});

  final PickedTask? ready;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  late var _ready = widget.ready;
  var _started = false;

  @override
  Widget build(BuildContext context) {
    final ready = _ready;
    if (ready == null || _started) {
      // *Start another task* ends the cycle and comes back to Ready.
      return LiveFocus(
        onReady: (picked) => setState(() {
          _ready = picked;
          _started = false;
        }),
      );
    }
    return ReadyScreen(
      key: ObjectKey(ready),
      picked: ready,
      onStarted: () => setState(() => _started = true),
    );
  }
}

/// Ready (spec §8.4, §4.7, §11.4): the pet; the framing line before the
/// phone has asked about notifications, or once after they were turned down
/// the denial line; the task row, which opens the picker; the length; and
/// *Start focusing*.
///
/// *Close* and Android back leave Focus and drop the pick: nothing has been
/// written yet.
class ReadyScreen extends ConsumerStatefulWidget {
  const ReadyScreen({super.key, required this.picked, required this.onStarted});

  final PickedTask picked;

  /// The block has started.
  final VoidCallback onStarted;

  @override
  ConsumerState<ReadyScreen> createState() => _ReadyScreenState();
}

class _ReadyScreenState extends ConsumerState<ReadyScreen> {
  late var _picked = widget.picked;

  /// The pair last chosen, read when Ready opens (spec §4.7).
  BlockLengths? _lengths;

  /// Whether this Ready shows the denial line: it hadn't been shown before
  /// it opened. It stays for as long as this Ready does.
  bool? _denialLineOwed;
  var _denialLineMarked = false;

  var _starting = false;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_readBeforeShowing());
  }

  Future<void> _readBeforeShowing() async {
    final settings = ref.read(settingsProvider);
    final lengths = BlockLengths(
      focusMinutes: await settings.lastFocusMinutes(),
      breakMinutes: await settings.lastBreakMinutes(),
    );
    final denialShown = await ref
        .read(deviceOnlyFileProvider)
        .notificationDenialShown();
    if (mounted) {
      setState(() {
        _lengths = lengths;
        _denialLineOwed = !denialShown;
      });
    }
  }

  Future<void> _changeTask() async {
    final picked = await pickTask(context, current: _picked.task);
    if (picked != null && mounted) setState(() => _picked = picked);
  }

  Future<void> _chooseLength(LengthChoice choice, BlockLengths now) async {
    final chosen = switch (choice) {
      LengthChoice.preset25 => BlockLengths.preset25,
      LengthChoice.preset50 => BlockLengths.preset50,
      LengthChoice.custom => await chooseCustomLengths(context, from: now),
    };
    if (chosen != null && mounted) setState(() => _lengths = chosen);
  }

  /// Asks the phone first if it never has (spec §11.4): the block anchors
  /// only once the dialog has closed, whatever the answer.
  Future<void> _start(BlockLengths lengths) async {
    setState(() {
      _starting = true;
      _failed = false;
    });
    final access = ref.read(notificationAccessProvider).value;
    if (access == NotificationAccess.notDetermined) {
      await ref.read(notificationAccessProvider.notifier).ask();
      // Left while the phone was asking: nothing starts.
      if (!mounted) return;
    }
    final settings = ref.read(settingsProvider);
    final task = _picked.task;
    final started = await ref
        .read(focusCycleServiceProvider)
        .startBlock(
          taskId: task.id,
          lengths: lengths,
          autoStart: await settings.autoStart(),
        );
    switch (started) {
      case Success():
        await settings.setLastLengths(
          focusMinutes: lengths.focusMinutes,
          breakMinutes: lengths.breakMinutes,
        );
        await settings.setLastProjectId(task.projectId);
        if (mounted) widget.onStarted();
      case Failure():
        if (mounted) {
          setState(() {
            _starting = false;
            _failed = true;
          });
        }
    }
  }

  /// The denial line shows on one Ready only: the first to open after
  /// notifications were turned down.
  bool _showsDenialLine(NotificationAccess? access) {
    if (access != NotificationAccess.denied || _denialLineOwed != true) {
      return false;
    }
    if (!_denialLineMarked) {
      _denialLineMarked = true;
      unawaited(ref.read(deviceOnlyFileProvider).setNotificationDenialShown());
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final access = ref.watch(notificationAccessProvider).value;
    final pet = ref.watch(petStandingProvider);
    final calmPet = ref.watch(calmPetProvider);
    final lengths = _lengths;

    final look = pet?.lookAt(
      ref.read(databaseProvider).clock(),
      calmPet: calmPet,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
    );
    final line = access == NotificationAccess.notDetermined
        ? words.permFrame
        : _showsDenialLine(access)
        ? words.permDenied
        : null;

    return ColoredBox(
      color: colours.ground,
      child: ScreenBody(
        content: [
          FocusHeader(
            picked: _picked,
            leading: PixelIconButton(
              icon: PixelIcon(IconName.close, colour: colours.ink),
              semanticLabel: words.focusLeave,
              onPressed: () => Navigator.of(context).pop(),
            ),
            notificationsOff: access == NotificationAccess.denied,
          ),
        ],
        middle: [
          if (look != null)
            Center(
              child: PetView(
                look: look,
                spot: PetSpot.focus,
                semanticLabel: petLabel(words, pet!, look),
              ),
            ),
          if (line != null) PixelText(line, textAlign: TextAlign.center),
        ],
        bottom: [
          _TaskRow(title: _picked.task.title, onPressed: _changeTask),
          if (lengths != null)
            _LengthControl(
              lengths: lengths,
              onChanged: (choice) => _chooseLength(choice, lengths),
            ),
          if (_failed)
            PixelBox(
              fill: colours.sunken,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: u(7), vertical: u(5)),
                child: PixelText(words.error),
              ),
            ),
          PixelButton(
            label: words.startFocusing,
            wide: true,
            onPressed: lengths == null || _starting
                ? null
                : () => _start(lengths),
          ),
        ],
      ),
    );
  }
}

/// Focus's header, every state (spec §8.4): [leading] at the top left
/// (*Close* on Ready, Minimise otherwise), the task's title and its project,
/// and the bell-off at the top right once notifications are turned down,
/// which opens the phone's settings.
///
/// The two icons sit 6 UI pixels into the side margins, as on the approved
/// screens, so their icons line up with the content.
class FocusHeader extends ConsumerWidget {
  const FocusHeader({
    super.key,
    required this.picked,
    required this.leading,
    required this.notificationsOff,
  });

  final PickedTask picked;
  final Widget leading;
  final bool notificationsOff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => OverflowBox(
        fit: OverflowBoxFit.deferToChild,
        minWidth: constraints.maxWidth + u(12),
        maxWidth: constraints.maxWidth + u(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading,
            SizedBox(width: u(4)),
            Expanded(
              child: Padding(
                // The title's first line sits level with the icon.
                padding: EdgeInsets.only(top: u(2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PixelText(
                      picked.task.title,
                      step: TypeStep.title,
                      header: true,
                    ),
                    PixelText(
                      picked.project.name,
                      step: TypeStep.caption,
                      colour: colours.muted,
                    ),
                  ],
                ),
              ),
            ),
            if (notificationsOff) ...[
              SizedBox(width: u(4)),
              PixelIconButton(
                icon: PixelIcon(IconName.bellOff, colour: colours.ink),
                semanticLabel: words.bellOff,
                onPressed: () => ref
                    .read(notificationAccessProvider.notifier)
                    .openSettings(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ready's task row: "Task" over the task's title, and a chevron. It opens
/// the picker.
class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.title, required this.onPressed});

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return Pressable(
      onPressed: onPressed,
      builder: (context, pressed, ring) => PixelBox(
        fill: pressed ? colours.pressed(colours.surface) : colours.surface,
        ring: ring ? colours.accent : null,
        child: Padding(
          padding: EdgeInsets.only(left: u(7), top: u(3), bottom: u(3)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PixelText(
                      words.readyTask,
                      step: TypeStep.caption,
                      colour: colours.muted,
                    ),
                    PixelText(title),
                  ],
                ),
              ),
              SizedBox(width: u(3)),
              SizedBox.square(
                dimension: u.target,
                child: Center(
                  child: PixelIcon(IconName.next, colour: colours.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Length" over **25 min / 50 min / Custom**. While a custom pair is
/// chosen the third reads *Custom · 15 min*.
class _LengthControl extends StatelessWidget {
  const _LengthControl({required this.lengths, required this.onChanged});

  final BlockLengths lengths;
  final ValueChanged<LengthChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final u = UiPixel.of(context);
    final choice = lengths.choice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(left: u(1)),
          child: PixelText(
            words.readyLength,
            step: TypeStep.caption,
            colour: TomoTheme.of(context).muted,
          ),
        ),
        SizedBox(height: u(3)),
        PixelSegmented<LengthChoice>(
          segments: [
            Segment(
              LengthChoice.preset25,
              words.lengthMinutes(BlockLengths.preset25.focusMinutes),
            ),
            Segment(
              LengthChoice.preset50,
              words.lengthMinutes(BlockLengths.preset50.focusMinutes),
            ),
            Segment(
              LengthChoice.custom,
              choice == LengthChoice.custom
                  ? words.customChip(lengths.focusMinutes)
                  : words.lengthCustom,
            ),
          ],
          selected: choice,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

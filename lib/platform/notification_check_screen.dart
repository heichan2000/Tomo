import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/data/instants.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/focus/block_lengths.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/task_status.dart';

import '../app/providers.dart';
import '../ui/buttons.dart';
import '../ui/screen_body.dart';
import '../ui/sharp_text.dart';
import '../ui/switch.dart';
import '../ui/tomo_theme.dart';
import 'notifications.dart';

/// The notification section of `docs/manual-checks.md`, made quick to run
/// on a real phone: the permission, exact alarms, what is pending, and
/// blocks to leave running. A builder's tool: its words are not in the copy
/// file and release builds never show it.
///
/// *1-minute block* writes the cycle itself, under the 10-minute floor, so a
/// check doesn't take ten minutes. It still credits the pet for its minute.
class NotificationCheckScreen extends ConsumerStatefulWidget {
  const NotificationCheckScreen({super.key});

  @override
  ConsumerState<NotificationCheckScreen> createState() =>
      _NotificationCheckScreenState();
}

class _NotificationCheckScreenState
    extends ConsumerState<NotificationCheckScreen> {
  var _autoStart = false;
  var _status = 'Reading…';

  @override
  void initState() {
    super.initState();
    unawaited(_read());
  }

  TomoDatabase get _db => ref.read(databaseProvider);

  Future<void> _read() async {
    final phone = ref.read(notificationSchedulerProvider);
    final exact = phone is PhoneNotifications ? await phone.canBeExact() : null;
    final pending = phone is PhoneNotifications
        ? [for (final request in await phone.pending()) request.id]
        : <int>[];
    final row = await _db.select(_db.focusCycle).getSingleOrNull();
    String time(int ms) {
      final at = utcFromMs(ms).toLocal();
      return '${at.hour.toString().padLeft(2, '0')}:'
          '${at.minute.toString().padLeft(2, '0')}:'
          '${at.second.toString().padLeft(2, '0')}';
    }

    if (!mounted) return;
    setState(() {
      _status = [
        'Exact alarms allowed: ${exact ?? 'not Android'}',
        'Pending now: ${pending.length}'
            '${pending.isEmpty ? '' : ' (ids ${pending.join(', ')})'}',
        if (row == null)
          'No cycle.'
        else
          'Cycle: ${row.focusMinutes} min, ends ${time(row.endAt)}'
              '${row.autoStart ? ', auto-start' : ''}'
              '${row.blockRecordId != null ? ', credited' : ''}',
        'Pending is always 0 while Tomo is open: leave, then come back.',
      ].join('\n');
    });
  }

  Future<int?> _taskId() async {
    final tasks = await _db.select(_db.tasks).get();
    final task = tasks.where((t) => t.status != TaskStatus.done).firstOrNull;
    if (task == null && mounted) {
      setState(() => _status = 'Add a task that is not done first.');
    }
    return task?.id;
  }

  /// A real block through the focus service, as Ready will start one.
  Future<void> _start(int minutes) async {
    final taskId = await _taskId();
    if (taskId == null) return;
    await ref.read(focusCycleServiceProvider).leave();
    final started = await ref
        .read(focusCycleServiceProvider)
        .startBlock(
          taskId: taskId,
          lengths: BlockLengths(focusMinutes: minutes, breakMinutes: 5),
          autoStart: _autoStart,
        );
    if (started is Failure) setState(() => _status = 'Refused: $started');
    await _read();
  }

  /// A block too short for the service: the row written directly, with a
  /// 1-minute break. The task's status is left as it is.
  Future<void> _startOneMinute() async {
    final taskId = await _taskId();
    if (taskId == null) return;
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await _db.delete(_db.focusCycle).go();
      await _db
          .into(_db.focusCycle)
          .insert(
            FocusCycleCompanion.insert(
              taskId: taskId,
              startAt: epochMs(now),
              endAt: epochMs(now.add(const Duration(minutes: 1))),
              focusMinutes: 1,
              breakMinutes: 1,
              autoStart: _autoStart,
            ),
          );
    });
    await ref.read(notificationSyncProvider).sync();
    await _read();
  }

  /// Plans the task the next block will be on at one more block than it
  /// has, so Focus's estimate card shows when that block ends (spec §4.9).
  /// The card shows once per task, ever: a fresh task shows it again.
  Future<void> _planOneMore() async {
    final taskId = await _taskId();
    if (taskId == null) return;
    final task = await (_db.select(
      _db.tasks,
    )..where((t) => t.id.equals(taskId))).getSingle();
    await _db.customStatement(
      'UPDATE tasks SET estimated_pomodoros = ? WHERE id = ?',
      [task.actualPomodoros + 1, taskId],
    );
    setState(
      () => _status = task.estimatePromptedAt == null
          ? 'Planned "${task.title}" at ${task.actualPomodoros + 1} blocks.'
          : '"${task.title}" has had its card already: add a fresh task.',
    );
  }

  Future<void> _end() async {
    await _db.delete(_db.focusCycle).go();
    await ref.read(notificationSyncProvider).sync();
    await _read();
  }

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final access = ref.watch(notificationAccessProvider);
    final permission = ref.read(notificationAccessProvider.notifier);
    Widget button(String label, Future<void> Function() action) => PixelButton(
      label: label,
      kind: ButtonKind.secondary,
      wide: true,
      onPressed: () => unawaited(action()),
    );

    return ColoredBox(
      color: colours.ground,
      child: ScreenBody(
        content: [
          const PixelText('Notification check', step: TypeStep.title),
          PixelText(
            'Permission: ${access.value?.name ?? 'reading…'}',
            colour: colours.ink,
          ),
          PixelText(_status, step: TypeStep.caption, colour: colours.muted),
          button('Read again', _read),
          button('Ask for the permission', () async {
            await permission.ask();
            await _read();
          }),
          button('Open the phone\'s settings', permission.openSettings),
          PixelSwitchRow(
            title: 'Auto-start',
            subtitle: 'For the blocks started here.',
            value: _autoStart,
            onChanged: (value) => setState(() => _autoStart = value),
          ),
          button('Start a 1-minute block', _startOneMinute),
          button('Start a 10-minute block', () => _start(10)),
          button('Start a 35-minute block (dozing)', () => _start(35)),
          button('Plan the task to end with its next block', _planOneMore),
          button('End the cycle', _end),
        ],
        bottom: [
          PixelButton(
            label: 'Back',
            kind: ButtonKind.secondary,
            wide: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

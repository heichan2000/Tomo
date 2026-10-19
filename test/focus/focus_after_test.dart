import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/focus/focus_screen.dart';
import 'package:tomo/focus/live_focus.dart';
import 'package:tomo/pet/reward_view.dart';
import 'package:tomo/ui/buttons.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/focus/focus_cycle_service.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_service.dart';
import 'package:tomo_core/tasks/task_status.dart';
import 'package:tomo_core/testing.dart';

import '../app/app_harness.dart';
import '../ui/kit_harness.dart';

/// What Focus shows when a block or a break ends: the beat run, then the
/// pet's line, the settled EXP bar and the choices; the estimate card; Break
/// over; and coming back to a block that finished away (spec §8.4, §8.5,
/// §7.4, §4.9, §10.4). Promises 8 (the card's half), 16 (Focus plays the
/// run), 18 (one spoken line per run) and 39 (the choices' half).
void main() {
  // Every test starts at nine; a block started then runs to 9:25.
  final nine = DateTime.utc(2026, 10, 18, 9);
  DateTime at(int minute, [int second = 0]) =>
      nine.add(Duration(minutes: minute, seconds: second));

  late TestClock clock;
  late TomoDatabase db;
  late WidgetTester current;
  late List<String> spoken;

  final log = Log(sinks: const []);
  T ok<T>(Result<T> result) => (result as Success<T>).value;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
    await petChanged(tester, db);
    await tester.pumpAndSettle();
  }

  /// The pet already hatched, named Pip, with [exp] EXP: 650 is level 2,
  /// with room before level 3.
  Future<void> hatched(TomoDatabase db, {int exp = 650}) => db.customStatement(
    'UPDATE pets SET name = ?, hatched_at = ?, exp = ?',
    ['Pip', nine.subtract(const Duration(days: 3)).millisecondsSinceEpoch, exp],
  );

  /// Opens the app at [minute] past nine, with [before] run then.
  Future<void> open(
    WidgetTester tester, {
    required Future<void> Function(TomoDatabase db) before,
    int minute = 0,
    double textScale = 1,
    ThemeName theme = ThemeName.light,
  }) async {
    current = tester;
    spoken = [];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (message) async {
        final event = message! as Map<Object?, Object?>;
        if (event['type'] == 'announce') {
          final data = event['data']! as Map<Object?, Object?>;
          spoken.add(data['message']! as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
            SystemChannels.accessibility,
            null,
          ),
    );
    clock = TestClock(nine);
    db = await pumpTomo(
      tester,
      clock: clock.call,
      before: (db) async {
        await before(db);
        clock.now = at(minute);
      },
      textScale: textScale,
      theme: theme,
    );
    await settle(tester);
  }

  Future<void> passTo(WidgetTester tester, int minute, [int second = 0]) async {
    final by = at(minute, second).difference(clock.now);
    clock.now = at(minute, second);
    await tester.pump(by);
    await settle(tester);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    // At large text the screen scrolls to it first.
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await settle(tester);
    // What the tap wrote reaches the screen.
    await settle(tester);
  }

  Finder button(String label) =>
      find.ancestor(of: find.words(label), matching: find.byType(PixelButton));

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await settle(tester);
  }

  Future<List<FocusCycleRow>> cycleRows() async =>
      (await current.runAsync(() => db.select(db.focusCycle).get()))!;
  Future<TaskRow> taskRow() async =>
      (await current.runAsync(() => db.select(db.tasks).getSingle()))!;
  Future<PetRow> petRow() async =>
      (await current.runAsync(() => db.select(db.pets).getSingle()))!;

  /// A hatched pet and a block started at nine on Write the intro.
  Future<void> block(TomoDatabase db) async {
    await hatched(db);
    await startBlockOn(db);
  }

  /// As [block], with the task planned at [estimate] blocks.
  Future<void> planned(TomoDatabase db, {int estimate = 1}) async {
    await hatched(db);
    final id = await startBlockOn(db);
    ok(
      await TaskService(
        db,
        log: log,
      ).updateTask(id, TaskPatch(estimate: Edit(estimate))),
    );
  }

  /// A block run out at 9:25 and seen, and its 5-minute break taken.
  Future<void> onBreak(TomoDatabase db) async {
    await block(db);
    clock.now = at(25);
    final focus = FocusCycleService(db, log: log);
    ok(await focus.takeBreak());
    ok(await focus.markBeatRunSeen());
  }

  const blockLine = 'Twenty-five minutes. They stay.';
  const taskLine = 'Write the intro is done. It stays done.';
  const breakOverLine = 'The break is whole. I am here.';
  const awayWords = 'the block is whole, with no one watching.';

  group('block done, on screen', () {
    testTomo('the beat plays, then the line, the bar and the choices', (
      tester,
    ) async {
      await open(tester, before: block, minute: 24);

      clock.now = at(25);
      await tester.pump(const Duration(minutes: 1));
      await settle(tester);

      expect(find.byType(RewardPet), findsOneWidget);
      expect(find.words(blockLine), findsOneWidget);
      expect(find.words('Lv 2'), findsOneWidget);
      expect(find.words('300 / 600 EXP'), findsOneWidget);
      expect(button('Take a 5-min break'), findsOneWidget);
      expect(button('Another 25-min block'), findsOneWidget);
      expect(button('Mark task done'), findsOneWidget);
      expect(find.words('Done for now'), findsNothing);
      expect(find.textContaining(awayWords), findsNothing);
      expect((await cycleRows()).single.seenAt, isNotNull);
    });

    testTomo('the run is spoken once, as it starts: facts, then the line', (
      tester,
    ) async {
      await open(tester, before: block, minute: 24);

      await passTo(tester, 25);

      expect(spoken, [
        'Block done: 25 minutes on Write the intro. Pip gained 250 EXP. '
            'Pip: $blockLine',
      ]);
    });

    testTomo('Take a 5-min break starts the break', (tester) async {
      await open(tester, before: block, minute: 24);
      await passTo(tester, 25);

      await tap(tester, button('Take a 5-min break'));

      expect(button('Skip break'), findsOneWidget);
      expect(find.words('about 5 min of rest left'), findsOneWidget);
    });

    testTomo('Another 25-min block starts one on the same task', (
      tester,
    ) async {
      await open(tester, before: block, minute: 24);
      await passTo(tester, 25);

      await tap(tester, button('Another 25-min block'));

      expect(find.words('about 25 min left'), findsOneWidget);
      expect(find.words('Write the intro'), findsWidgets);
    });

    testTomo('Android back is Leave', (tester) async {
      await open(tester, before: block, minute: 24);
      await passTo(tester, 25);

      await back(tester);

      expect(find.byType(LiveFocus), findsNothing);
      expect(await cycleRows(), isEmpty);
    });
  });

  group('mark task done', () {
    testTomo('Task done plays, then a break, another task, or leave', (
      tester,
    ) async {
      await open(tester, before: block, minute: 24);
      await passTo(tester, 25);
      spoken.clear();

      await tap(tester, button('Mark task done'));

      expect(find.words(taskLine), findsOneWidget);
      expect(button('Take a 5-min break'), findsOneWidget);
      expect(button('Start another task'), findsOneWidget);
      expect(button('Done for now'), findsOneWidget);
      expect(find.words('Another 25-min block'), findsNothing);
      expect((await taskRow()).status, TaskStatus.done);
      // The bonus: the task's own 25 minutes.
      expect((await petRow()).exp, 650 + 250 + 25);
      expect(spoken, [
        'Task done: Write the intro. Pip gained 25 EXP. Pip: $taskLine',
      ]);
      // The cycle carries on.
      expect(await cycleRows(), hasLength(1));
    });

    testTomo('Done for now ends the cycle and closes Focus', (tester) async {
      await open(tester, before: block, minute: 24);
      await passTo(tester, 25);
      await tap(tester, button('Mark task done'));

      await tap(tester, button('Done for now'));

      expect(find.byType(LiveFocus), findsNothing);
      expect(await cycleRows(), isEmpty);
    });

    testTomo('Start another task picks one, and Focus is Ready on it', (
      tester,
    ) async {
      await open(
        tester,
        before: (db) async {
          await block(db);
          final tasks = TaskService(db, log: log);
          final project = (await tasks.projects()).first;
          ok(await tasks.createTask(projectId: project.id, title: 'Edit ch 2'));
        },
        minute: 24,
      );
      await passTo(tester, 25);
      await tap(tester, button('Mark task done'));

      await tap(tester, button('Start another task'));
      await tap(tester, find.words('Edit ch 2'));

      expect(find.byType(ReadyScreen), findsOneWidget);
      expect(find.words('Edit ch 2'), findsWidgets);
      expect(await cycleRows(), isEmpty);
    });

    testTomo('a task marked done on Work since offers no next block', (
      tester,
    ) async {
      await open(
        tester,
        before: (db) async {
          await block(db);
          // Marked done once the block had run out, away from Focus.
          clock.now = at(26);
          final tasks = TaskService(db, log: log);
          final task = (await tasks.pickerTasks()).single;
          ok(
            await tasks.updateTask(
              task.id,
              const TaskPatch(status: TaskStatus.done),
            ),
          );
        },
        minute: 30,
      );

      expect(button('Take a 5-min break'), findsOneWidget);
      expect(button('Start another task'), findsOneWidget);
      expect(find.words('Another 25-min block'), findsNothing);
      expect(find.words('Mark task done'), findsNothing);
    });
  });

  group('the estimate card', () {
    testTomo('after the beat, above the choices; Mark task done hides', (
      tester,
    ) async {
      await open(tester, before: planned, minute: 24);
      await passTo(tester, 25);

      expect(find.words('Is this task done?'), findsOneWidget);
      expect(find.words('Every planned block is here.'), findsOneWidget);
      expect(button('Not yet'), findsOneWidget);
      expect(button('Mark done'), findsOneWidget);
      expect(find.words('Mark task done'), findsNothing);
      expect((await taskRow()).estimatePromptedAt, isNotNull);
    });

    testTomo('Not yet puts it away, and Mark task done is back', (
      tester,
    ) async {
      await open(tester, before: planned, minute: 24);
      await passTo(tester, 25);

      await tap(tester, button('Not yet'));

      expect(find.words('Is this task done?'), findsNothing);
      expect(button('Mark task done'), findsOneWidget);
      expect((await taskRow()).status, TaskStatus.doing);
    });

    testTomo('Mark done marks the task done, with its celebration', (
      tester,
    ) async {
      await open(tester, before: planned, minute: 24);
      await passTo(tester, 25);

      await tap(tester, button('Mark done'));

      expect(find.words('Is this task done?'), findsNothing);
      expect(find.words(taskLine), findsOneWidget);
      expect(button('Start another task'), findsOneWidget);
      expect((await taskRow()).status, TaskStatus.done);
    });

    testTomo('any choice counts as not yet, and it never comes back', (
      tester,
    ) async {
      await open(tester, before: (db) => planned(db), minute: 24);
      await passTo(tester, 25);

      await tap(tester, button('Another 25-min block'));
      await passTo(tester, 50);

      expect(find.words(blockLine), findsOneWidget);
      expect(find.words('Is this task done?'), findsNothing);
      expect(button('Mark task done'), findsOneWidget);
    });
  });

  group('break over', () {
    testTomo('its line, then another block, mark done, or leave', (
      tester,
    ) async {
      await open(tester, before: onBreak, minute: 29);

      await passTo(tester, 30);

      expect(find.words(breakOverLine), findsOneWidget);
      expect(button('Start another block'), findsOneWidget);
      expect(button('Mark task done'), findsOneWidget);
      expect(button('Done for now'), findsOneWidget);
    });

    testTomo('Start another block starts one', (tester) async {
      await open(tester, before: onBreak, minute: 31);

      await tap(tester, button('Start another block'));

      expect(find.words('about 25 min left'), findsOneWidget);
    });

    testTomo('Mark task done: Task done, then another task or leave', (
      tester,
    ) async {
      await open(tester, before: onBreak, minute: 31);

      await tap(tester, button('Mark task done'));

      expect(find.words(taskLine), findsOneWidget);
      expect(button('Start another task'), findsOneWidget);
      expect(button('Done for now'), findsOneWidget);
      expect(find.words('Start another block'), findsNothing);
      expect(find.words('Take a 5-min break'), findsNothing);
    });

    testTomo('Android back is Leave', (tester) async {
      await open(tester, before: onBreak, minute: 31);

      await back(tester);

      expect(find.byType(LiveFocus), findsNothing);
      expect(await cycleRows(), isEmpty);
    });
  });

  group('coming back to a block that finished away', () {
    testTomo('the note, the full beat, then the choices', (tester) async {
      await open(tester, before: block, minute: 40);

      expect(find.byType(LiveFocus), findsOneWidget);
      expect(find.textContaining(awayWords), findsOneWidget);
      expect(find.words(blockLine), findsOneWidget);
      expect(button('Take a 5-min break'), findsOneWidget);
      expect(spoken, hasLength(1));
      expect(spoken.single, contains(awayWords));
      expect(spoken.single, endsWith('Pip gained 250 EXP. Pip: $blockLine'));
      expect(spoken.single, isNot(contains('Block done:')));
    });

    testTomo('the note stays until a choice is picked', (tester) async {
      await open(tester, before: block, minute: 40);

      await passTo(tester, 41);
      expect(find.textContaining(awayWords), findsOneWidget);

      await tap(tester, button('Take a 5-min break'));
      expect(find.textContaining(awayWords), findsNothing);
    });
  });

  testTomo('the first block: the hatch, then the choices', (tester) async {
    await open(tester, before: startBlockOn, minute: 24);

    await passTo(tester, 25);
    // The naming's Done (focus_hatch_test.dart has the rest of it).
    await tap(tester, find.words('Done'));

    expect(button('Take a 5-min break'), findsOneWidget);
    expect((await cycleRows()).single.seenAt, isNotNull);
  });

  testTomo('at 200% text, every after state scrolls rather than clips', (
    tester,
  ) async {
    await open(
      tester,
      before: planned,
      minute: 40,
      textScale: 2,
      theme: ThemeName.dark,
    );
    expect(find.words('Is this task done?'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tap(tester, button('Mark done'));
    expect(button('Done for now'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tap(tester, button('Take a 5-min break'));
    await passTo(tester, 46);
    expect(button('Start another task'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

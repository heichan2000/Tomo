import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/running_banner.dart';
import 'package:tomo/focus/clock_view.dart';
import 'package:tomo/focus/live_focus.dart';
import 'package:tomo/home/home_screen.dart';
import 'package:tomo/pet/pet_view.dart';
import 'package:tomo/ui/buttons.dart';
import 'package:tomo/ui/rows.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/focus/focus_cycle_service.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/pet/pet_look.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_service.dart';
import 'package:tomo_core/tasks/task_status.dart';
import 'package:tomo_core/testing.dart';

import '../app/app_harness.dart';
import '../ui/kit_harness.dart';

/// Focus while a block or a break runs, Stop early, the countdown, and the
/// banner (spec §8.1, §8.4, §8.6, §4.8, ADR-0003, ADR-0010, ADR-0011).
/// Promises 6 (the countdown's half), 20 (the widget half), 31, 32 and 33
/// (the clock's half).
void main() {
  // Every test starts at nine; a block started then runs to 9:25.
  final nine = DateTime.utc(2026, 10, 18, 9);
  DateTime at(int minute, [int second = 0]) =>
      nine.add(Duration(minutes: minute, seconds: second));

  late TestClock clock;
  late TomoDatabase db;
  late WidgetTester current;

  final log = Log(sinks: const []);
  T ok<T>(Result<T> result) => (result as Success<T>).value;

  /// Lets the database work on the real clock, tells the screens what it
  /// now holds, and settles.
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

  /// Opens the app at [minute] past nine, with [before] run then.
  Future<void> open(
    WidgetTester tester, {
    required Future<void> Function(TomoDatabase db) before,
    int minute = 0,
    double textScale = 1,
    ThemeName theme = ThemeName.light,
  }) async {
    current = tester;
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
  }

  /// Moves the clock, and the app's timers with it, to [minute]:[second]
  /// past nine.
  Future<void> passTo(WidgetTester tester, int minute, [int second = 0]) async {
    final by = at(minute, second).difference(clock.now);
    clock.now = at(minute, second);
    await tester.pump(by);
    await settle(tester);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await settle(tester);
  }

  Finder button(String label) =>
      find.ancestor(of: find.words(label), matching: find.byType(PixelButton));

  Finder minimise() => find.byWidgetPredicate(
    (widget) => widget is PixelIconButton && widget.semanticLabel == 'Minimise',
  );

  Finder banner() => find.byType(RunningBannerSlot);
  Finder inBanner(String words) =>
      find.descendant(of: banner(), matching: find.words(words));

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await settle(tester);
  }

  Future<List<FocusCycleRow>> cycleRows() async =>
      (await current.runAsync(() => db.select(db.focusCycle).get()))!;
  Future<List<BlockRecordRow>> records() async =>
      (await current.runAsync(() => db.select(db.blockRecords).get()))!;

  /// A block started at nine, its beat seen and its break taken at 9:25.
  Future<void> onBreak(TomoDatabase db, {bool autoStart = false}) async {
    await startBlockOn(db, autoStart: autoStart);
    clock.now = at(25);
    final focus = FocusCycleService(db, log: log);
    if (!autoStart) ok(await focus.takeBreak());
    // The block's beat was had on Focus as it ended.
    ok(await focus.markBeatRunSeen());
  }

  group('a block running', () {
    testTomo('the pet, the quiet clock, the Focus chip and Stop early', (
      tester,
    ) async {
      await open(tester, before: startBlockOn);

      expect(find.byType(LiveFocus), findsOneWidget);
      expect(find.words('Write the intro'), findsOneWidget);
      expect(minimise(), findsOneWidget);
      expect(find.byType(PetView), findsOneWidget);
      expect(find.words('about 25 min left'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is PixelChip && w.label == 'Focus' && w.big,
        ),
        findsOneWidget,
      );
      expect(button('Stop early'), findsOneWidget);
    });

    testTomo('the clock reads rough minutes as the block goes', (tester) async {
      await open(tester, before: startBlockOn);

      await passTo(tester, 6, 18);
      expect(find.words('about 19 min left'), findsOneWidget);
      await passTo(tester, 6, 30);
      expect(find.words('about 18 min left'), findsOneWidget);
      await passTo(tester, 24, 10);
      expect(find.words('under a minute left'), findsOneWidget);
    });

    testTomo('a tap on the clock shows the exact time for 5 s', (tester) async {
      await open(tester, before: startBlockOn, minute: 6);
      clock.now = at(6, 18);

      await tester.tap(find.byType(QuietClock));
      await tester.pump();
      expect(find.words('18:42'), findsOneWidget);

      clock.now = at(6, 19);
      await tester.pump(const Duration(seconds: 1));
      expect(find.words('18:41'), findsOneWidget);

      clock.now = at(6, 23);
      await tester.pump(const Duration(seconds: 4));
      expect(find.words('about 19 min left'), findsOneWidget);
      expect(find.words('18:37'), findsNothing);
    });

    testTomo('to a screen reader the clock is rough minutes, never live', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await open(tester, before: startBlockOn, minute: 6);

      const label = 'About 19 minutes left on Write the intro.';
      final clockNode = tester.getSemantics(find.bySemanticsLabel(label));
      expect(clockNode.flagsCollection.isLiveRegion, isFalse);

      // The exact time is for the eye; the label stays in rough minutes.
      await tester.tap(find.byType(QuietClock));
      await tester.pump();
      expect(find.bySemanticsLabel(label), findsOneWidget);
      semantics.dispose();
    });

    testTomo('on the first block the egg cracks in the pet\'s place', (
      tester,
    ) async {
      await open(tester, before: startBlockOn);
      final whole = tester.widget<PetView>(find.byType(PetView)).look;
      expect(whole, isA<EggLook>().having((e) => e.picture, 'picture', 0));

      await passTo(tester, 13);

      final cracked = tester.widget<PetView>(find.byType(PetView)).look;
      expect(cracked, isA<EggLook>().having((e) => e.picture, 'picture', 2));
    });
  });

  group('Stop early', () {
    testTomo('asks first; Keep going changes nothing', (tester) async {
      await open(tester, before: startBlockOn, minute: 10);

      await tap(tester, button('Stop early'));
      expect(find.words('Stop this block?'), findsOneWidget);
      final keep = tester.getRect(button('Keep going'));
      final stop = tester.getRect(
        find.byWidgetPredicate(
          (w) => w is PixelButton && w.kind == ButtonKind.destructive,
        ),
      );
      // 8 UI pixels: at 2.625×, 8 × 4 dots.
      expect(stop.top - keep.bottom, closeTo(32 / 2.625, 1e-6));

      await tap(tester, button('Keep going'));
      expect(find.words('Stop this block?'), findsNothing);
      expect(find.words('about 15 min left'), findsOneWidget);
      expect(await cycleRows(), hasLength(1));
    });

    testTomo('stopping closes Focus and leaves no trace', (tester) async {
      await open(tester, before: startBlockOn, minute: 10);

      await tap(tester, button('Stop early'));
      await tap(
        tester,
        find.byWidgetPredicate(
          (w) => w is PixelButton && w.kind == ButtonKind.destructive,
        ),
      );

      expect(find.byType(LiveFocus), findsNothing);
      expect(find.byType(HomeScreen).hitTestable(), findsOneWidget);
      expect(await cycleRows(), isEmpty);
      expect(await records(), isEmpty);
      // The egg is whole again on Home: it was never seen closing.
      final egg = tester.widget<PetView>(find.byType(PetView)).look;
      expect(egg, isA<EggLook>().having((e) => e.picture, 'picture', 0));
      expect(inBanner('Write the intro'), findsNothing);
    });

    testTomo('a block that ends while the sheet is open counts', (
      tester,
    ) async {
      await open(tester, before: startBlockOn, minute: 24);

      await tap(tester, button('Stop early'));
      expect(find.words('Stop this block?'), findsOneWidget);

      await passTo(tester, 25);

      expect(find.words('Stop this block?'), findsNothing);
      expect(find.byType(LiveFocus), findsOneWidget);
      expect(await records(), hasLength(1));
    });

    testTomo('Android back closes only the sheet', (tester) async {
      await open(tester, before: startBlockOn, minute: 10);
      await tap(tester, button('Stop early'));

      await back(tester);

      expect(find.words('Stop this block?'), findsNothing);
      expect(find.byType(LiveFocus).hitTestable(), findsOneWidget);
      expect(await cycleRows(), hasLength(1));
    });
  });

  group('minimise and the banner', () {
    testTomo('minimising ends nothing and docks the banner on every tab', (
      tester,
    ) async {
      await open(tester, before: startBlockOn, minute: 6);

      await tap(tester, minimise());

      expect(find.byType(LiveFocus), findsNothing);
      expect(await cycleRows(), hasLength(1));
      expect(inBanner('Write the intro'), findsOneWidget);
      expect(inBanner('19 min left'), findsOneWidget);

      await tap(tester, find.words('Work'));
      expect(inBanner('Write the intro').hitTestable(), findsOneWidget);

      await tap(tester, inBanner('Write the intro'));
      expect(find.byType(LiveFocus).hitTestable(), findsOneWidget);
    });

    testTomo('Android back while a block runs minimises', (tester) async {
      await open(tester, before: startBlockOn, minute: 6);

      await back(tester);

      expect(find.byType(LiveFocus), findsNothing);
      expect(inBanner('19 min left'), findsOneWidget);
      expect(await cycleRows(), hasLength(1));
    });

    testTomo('the banner keeps rough minutes', (tester) async {
      await open(tester, before: startBlockOn, minute: 6);
      await tap(tester, minimise());

      await passTo(tester, 16);
      expect(inBanner('9 min left'), findsOneWidget);
      await passTo(tester, 24, 30);
      expect(inBanner('under a minute left'), findsOneWidget);
    });

    testTomo('a block that ends while minimised: the finished strip', (
      tester,
    ) async {
      await open(tester, before: startBlockOn, minute: 20);
      await tap(tester, minimise());

      await passTo(tester, 25);

      expect(inBanner('Block done · 25 min counted'), findsOneWidget);
      expect(await records(), hasLength(1));
    });

    testTomo('a break on the banner, then Break over', (tester) async {
      await open(tester, before: onBreak, minute: 26);
      await tap(tester, minimise());

      expect(inBanner('Break · about 4 min'), findsOneWidget);

      await passTo(tester, 30);
      expect(inBanner('Break over'), findsOneWidget);
    });
  });

  group('a break', () {
    testTomo('the pet, its line, rest minutes, the Break chip, Skip break', (
      tester,
    ) async {
      await open(tester, before: onBreak, minute: 26);

      expect(
        find.words("It's break time. Twenty-five minutes today."),
        findsOneWidget,
      );
      expect(find.words('about 4 min of rest left'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is PixelChip && w.label == 'Break' && w.big,
        ),
        findsOneWidget,
      );
      expect(find.words(autoNote), findsNothing);

      await tap(tester, button('Skip break'));

      expect(find.words('Skip break'), findsNothing);
      expect(find.words('Start another block'), findsOneWidget);
    });

    testTomo('started by auto-start, the note says why', (tester) async {
      await open(
        tester,
        before: (db) => onBreak(db, autoStart: true),
        minute: 26,
      );

      expect(find.words(autoNote), findsOneWidget);
      expect(find.words('about 4 min of rest left'), findsOneWidget);
    });

    testTomo('Android back minimises', (tester) async {
      await open(tester, before: onBreak, minute: 26);

      await back(tester);

      expect(find.byType(LiveFocus), findsNothing);
      expect(await cycleRows(), hasLength(1));
    });
  });

  group('next block in 10', () {
    Future<void> autoBreak(TomoDatabase db) => onBreak(db, autoStart: true);

    testTomo('a break that ends on screen counts the next block down', (
      tester,
    ) async {
      await open(tester, before: autoBreak, minute: 29);

      await passTo(tester, 30);
      expect(
        find.words('Steady. The next block begins in ten.'),
        findsOneWidget,
      );
      expect(button('Start now'), findsOneWidget);
      expect(button('Not yet'), findsOneWidget);

      await passTo(tester, 30, 4);
      expect(
        find.words('Steady. The next block begins in six.'),
        findsOneWidget,
      );

      await passTo(tester, 30, 10);
      expect(find.words('about 25 min left'), findsOneWidget);
      final rows = await cycleRows();
      expect(rows.single.startAt, at(30, 10).millisecondsSinceEpoch);
      expect(rows.single.focusMinutes, 25);
    });

    testTomo('Start now starts it at once', (tester) async {
      await open(tester, before: autoBreak, minute: 29);
      await passTo(tester, 30);

      await tap(tester, button('Start now'));

      expect(find.words('about 25 min left'), findsOneWidget);
    });

    testTomo('Not yet stays on Break over, and nothing starts', (tester) async {
      await open(tester, before: autoBreak, minute: 29);
      await passTo(tester, 30);

      await tap(tester, button('Not yet'));
      await passTo(tester, 31);

      expect(find.words('Start another block'), findsOneWidget);
      expect(find.textContaining('next block'), findsNothing);
      expect((await cycleRows()).single.startAt, nine.millisecondsSinceEpoch);
    });

    testTomo('a break that ended while away starts nothing', (tester) async {
      await open(tester, before: autoBreak, minute: 31);

      await passTo(tester, 32);

      expect(find.words('Start another block'), findsOneWidget);
      expect(find.words('Start now'), findsNothing);
    });

    testTomo('a skipped break starts nothing', (tester) async {
      await open(tester, before: autoBreak, minute: 26);

      await tap(tester, button('Skip break'));
      await passTo(tester, 27);

      expect(find.words('Start another block'), findsOneWidget);
      expect(find.words('Start now'), findsNothing);
    });

    testTomo('a done task gets no countdown', (tester) async {
      await open(
        tester,
        before: (db) async {
          await autoBreak(db);
          final tasks = TaskService(db, log: log);
          final task = (await tasks.pickerTasks()).single;
          ok(
            await tasks.updateTask(
              task.id,
              const TaskPatch(status: TaskStatus.done),
            ),
          );
        },
        minute: 29,
      );

      await passTo(tester, 30);

      expect(find.words('Start now'), findsNothing);
    });
  });

  testTomo('at 200% text, every state scrolls rather than clips', (
    tester,
  ) async {
    await open(
      tester,
      before: (db) => onBreak(db, autoStart: true),
      minute: 26,
      textScale: 2,
      theme: ThemeName.dark,
    );
    expect(tester.takeException(), isNull);

    await passTo(tester, 30);
    expect(find.byType(LiveFocus), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tap(tester, button('Start now'));
    expect(tester.takeException(), isNull);

    await tap(tester, button('Stop early'));
    expect(find.words('Stop this block?'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tap(tester, button('Keep going'));
    await tap(tester, minimise());
    expect(tester.takeException(), isNull);
    await passTo(tester, 56);
    expect(inBanner('Block done · 25 min counted'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const autoNote =
    'Break started on its own. Auto-start is on (change it in Settings).';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/focus/live_focus.dart';
import 'package:tomo/app/providers.dart';
import 'package:tomo/app/tomo_app.dart';
import 'package:tomo/focus/focus_screen.dart';
import 'package:tomo/focus/length_sheet.dart';
import 'package:tomo/focus/task_picker.dart';
import 'package:tomo/pet/pet_view.dart';
import 'package:tomo/ui/buttons.dart';
import 'package:tomo/ui/rows.dart';
import 'package:tomo/ui/segmented.dart';
import 'package:tomo/ui/sharp_text.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/focus/block_lengths.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_service.dart';
import 'package:tomo_core/tasks/task_status.dart';

import '../app/app_harness.dart';
import '../platform/fake_notifications.dart';
import '../ui/kit_harness.dart';

/// The task picker and Focus's Ready (spec §8.1, §8.4, §4.7, §11.4).
void main() {
  /// Lets the database and the stores work on the real clock, then settles.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pumpAndSettle();
    }
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await settle(tester);
  }

  Finder button(String label) =>
      find.ancestor(of: find.words(label), matching: find.byType(PixelButton));

  Finder iconButton(String label) => find.byWidgetPredicate(
    (widget) => widget is PixelIconButton && widget.semanticLabel == label,
  );

  Finder row(String title) => find.byWidgetPredicate(
    (widget) => widget is PixelRow && widget.title == title,
  );

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(TomoApp)));

  /// Two projects with a task each besides the harness's empty "Things":
  /// "Read the paper" (to-do, in Thesis), "Pack books" (doing, in Moving),
  /// and "Old task" (done, in Thesis).
  Future<void> someTasks(TomoDatabase db) async {
    final tasks = TaskService(db, log: Log(sinks: const []));
    T ok<T>(Result<T> result) => (result as Success<T>).value;
    final thesis = ok(await tasks.createProject('Thesis'));
    final moving = ok(await tasks.createProject('Moving'));
    ok(await tasks.createTask(projectId: thesis.id, title: 'Read the paper'));
    final old = ok(
      await tasks.createTask(projectId: thesis.id, title: 'Old task'),
    );
    ok(
      await tasks.updateTask(old.id, const TaskPatch(status: TaskStatus.done)),
    );
    // So Moving is plainly the most recently active.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final pack = ok(
      await tasks.createTask(projectId: moving.id, title: 'Pack books'),
    );
    ok(
      await tasks.updateTask(
        pack.id,
        const TaskPatch(status: TaskStatus.doing),
      ),
    );
  }

  Future<void> openPicker(WidgetTester tester) =>
      tap(tester, find.words('Start focusing'));

  /// Home → the picker → Ready on [title].
  Future<void> openReady(WidgetTester tester, String title) async {
    await openPicker(tester);
    await tap(tester, row(title));
  }

  Future<List<FocusCycleRow>> cycles(
    WidgetTester tester,
    TomoDatabase db,
  ) async => (await tester.runAsync(() => db.select(db.focusCycle).get()))!;

  group('the task picker', () {
    testTomo('one list from every project: doing, then to-do, never done', (
      tester,
    ) async {
      await pumpTomo(tester, before: someTasks);
      await openPicker(tester);

      expect(find.words('Choose a task'), findsOneWidget);
      final rows = tester.widgetList<PixelRow>(find.byType(PixelRow));
      expect(
        [for (final r in rows) (r.title, r.subtitle)],
        [('Pack books', 'Moving'), ('Read the paper', 'Thesis')],
      );
      expect(
        find.descendant(of: row('Pack books'), matching: find.words('Doing')),
        findsOneWidget,
      );
      expect(find.words('Old task'), findsNothing);
    });

    testTomo('picking a task opens Focus on Ready, over the tab bar', (
      tester,
    ) async {
      await pumpTomo(tester, before: someTasks);
      await openReady(tester, 'Read the paper');

      expect(find.byType(ReadyScreen), findsOneWidget);
      final header = find.byType(FocusHeader);
      expect(
        find.descendant(of: header, matching: find.words('Read the paper')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: header, matching: find.words('Thesis')),
        findsOneWidget,
      );
      expect(find.words('Home').hitTestable(), findsNothing);
      expect(find.byType(PetView), findsOneWidget);
    });

    testTomo('dismissed, nothing opens', (tester) async {
      await pumpTomo(tester, before: someTasks);
      await openPicker(tester);
      await tester.binding.handlePopRoute();
      await settle(tester);

      expect(find.byType(TaskPickerSheet), findsNothing);
      expect(find.byType(FocusScreen), findsNothing);
    });

    testTomo('New task adds a to-do task to the most recently active '
        'project and goes', (tester) async {
      final db = await pumpTomo(tester, before: someTasks);
      await openPicker(tester);
      // Moving had the latest activity: its task was added last.
      expect(find.words('Moving'), findsWidgets);

      await tester.enterText(find.byType(EditableText), '  Label boxes ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);

      expect(find.byType(ReadyScreen), findsOneWidget);
      final added = await tester.runAsync(
        () => (db.select(
          db.tasks,
        )..where((t) => t.title.equals('Label boxes'))).getSingle(),
      );
      expect(added!.status, TaskStatus.todo);
      final moving = await tester.runAsync(
        () => (db.select(
          db.projects,
        )..where((p) => p.name.equals('Moving'))).getSingle(),
      );
      expect(added.projectId, moving!.id);
      expect(
        await tester.runAsync(
          () => container(tester).read(settingsProvider).lastProjectId(),
        ),
        moving.id,
      );
    });

    testTomo('the project chip changes where New task goes', (tester) async {
      final db = await pumpTomo(tester, before: someTasks);
      await openPicker(tester);

      await tap(
        tester,
        find.bySemanticsLabel('Goes in Moving. Change project'),
      );
      expect(find.words('Choose a project'), findsOneWidget);
      await tap(tester, row('Thesis'));
      expect(
        find.bySemanticsLabel('Goes in Thesis. Change project'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(EditableText), 'Cite sources');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);

      final header = find.byType(FocusHeader);
      expect(
        find.descendant(of: header, matching: find.words('Thesis')),
        findsOneWidget,
      );
      final added = await tester.runAsync(
        () => (db.select(
          db.tasks,
        )..where((t) => t.title.equals('Cite sources'))).getSingle(),
      );
      expect(added, isNotNull);
    });

    testTomo('a blank New task adds nothing', (tester) async {
      final db = await pumpTomo(tester, before: someTasks);
      await openPicker(tester);

      await tester.enterText(find.byType(EditableText), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);

      expect(find.byType(TaskPickerSheet), findsOneWidget);
      final count = await tester.runAsync(
        () => db.select(db.tasks).get().then((t) => t.length),
      );
      expect(count, 3);
    });

    testTomo('with no project left, New task goes into a new My work', (
      tester,
    ) async {
      final db = await pumpTomo(
        tester,
        before: (db) => db.delete(db.projects).go(),
      );
      await openPicker(tester);

      await tester.enterText(find.byType(EditableText), 'Begin again');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);

      expect(
        find.descendant(
          of: find.byType(FocusHeader),
          matching: find.words('My work'),
        ),
        findsOneWidget,
      );
      final projects = await tester.runAsync(
        () => db.select(db.projects).get(),
      );
      expect([for (final p in projects!) p.name], ['My work']);
    });
  });

  group('Ready', () {
    testTomo("the task row opens the picker, the current task checked; "
        'picking another changes it', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpTomo(tester, before: someTasks);
      await openReady(tester, 'Read the paper');

      await tap(tester, find.words('Task'));
      expect(find.byType(TaskPickerSheet), findsOneWidget);
      expect(
        tester.getSemantics(row('Read the paper')),
        matchesSemantics(
          isSelected: true,
          hasSelectedState: true,
          isButton: true,
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasFocusAction: true,
          label: 'Read the paper\nThesis',
        ),
      );

      await tap(tester, row('Pack books'));
      final header = find.byType(FocusHeader);
      expect(
        find.descendant(of: header, matching: find.words('Pack books')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: header, matching: find.words('Moving')),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testTomo(
      'the first time, the length is 25 min, and Custom shows no length',
      (tester) async {
        await pumpTomo(tester, before: someTasks);
        await openReady(tester, 'Read the paper');

        expect(find.words('Length'), findsOneWidget);
        expect(find.words('25 min'), findsOneWidget);
        expect(find.words('50 min'), findsOneWidget);
        expect(find.words('Custom'), findsOneWidget);
        expect(
          tester
              .widget<PixelSegmented<LengthChoice>>(
                find.byType(PixelSegmented<LengthChoice>),
              )
              .selected,
          LengthChoice.preset25,
        );
      },
    );

    // The Galaxy's 2.8125× is 384 points wide; the emulator's 2.625×, 411.
    for (final (dpr, size) in [
      (2.625, const Size(1080, 2400)),
      (2.8125, const Size(1080, 2316)),
    ]) {
      testTomo('at $dpr× the length is one row of three, one height, '
          'whichever is chosen', (tester) async {
        await pumpTomo(tester, dpr: dpr, physicalSize: size, before: someTasks);
        await openReady(tester, 'Read the paper');

        Finder option(String label) => find
            .ancestor(of: find.words(label), matching: find.byType(Pressable))
            .first;
        void inOneRow(List<String> labels) {
          final first = tester.getRect(option(labels.first));
          for (final label in labels) {
            final box = tester.getRect(option(label));
            expect(box.top, first.top, reason: label);
            expect(box.height, first.height, reason: label);
          }
        }

        inOneRow(['25 min', '50 min', 'Custom']);
        await tap(tester, find.words('Custom'));
        await tap(tester, find.bySemanticsLabel('More').first);
        await tap(tester, find.words('Use these'));
        inOneRow(['25 min', '50 min', 'Custom\n30 min']);
      });
    }

    testTomo('Custom: Focus 10–120 in fives, Break 1–30, then Use these', (
      tester,
    ) async {
      await pumpTomo(tester, before: someTasks);
      await openReady(tester, 'Read the paper');

      await tap(tester, find.words('Custom'));
      expect(find.words('Custom length'), findsOneWidget);
      final fewer = find.bySemanticsLabel('Fewer');
      final more = find.bySemanticsLabel('More');

      // Focus: 25 → 10, and no lower.
      for (var i = 0; i < 3; i++) {
        await tap(tester, fewer.first);
      }
      expect(find.words('10 min'), findsOneWidget);
      expect(
        tester
            .widget<Pressable>(
              find
                  .ancestor(of: fewer.first, matching: find.byType(Pressable))
                  .first,
            )
            .onPressed,
        isNull,
      );
      await tap(tester, more.first);
      await tap(tester, more.first);
      expect(find.words('20 min'), findsOneWidget);
      // Break: 5 → 7.
      await tap(tester, more.last);
      await tap(tester, more.last);
      expect(find.words('7 min'), findsOneWidget);

      await tap(tester, find.words('Use these'));
      expect(find.byType(CustomLengthSheet), findsNothing);
      expect(find.words('Custom\n20 min'), findsOneWidget);
    });

    testTomo('a custom pair equal to a preset shows as the preset', (
      tester,
    ) async {
      await pumpTomo(tester, before: someTasks);
      await openReady(tester, 'Read the paper');

      await tap(tester, find.words('Custom'));
      // 25 → 20 → 25: back where it began.
      await tap(tester, find.bySemanticsLabel('Fewer').first);
      await tap(tester, find.bySemanticsLabel('More').first);
      await tap(tester, find.words('Use these'));

      expect(find.words('Custom'), findsOneWidget);
      expect(
        tester
            .widget<PixelSegmented<LengthChoice>>(
              find.byType(PixelSegmented<LengthChoice>),
            )
            .selected,
        LengthChoice.preset25,
      );
    });

    testTomo('Close and Android back leave Focus and write nothing', (
      tester,
    ) async {
      final db = await pumpTomo(tester, before: someTasks);
      await openReady(tester, 'Read the paper');
      await tap(tester, iconButton('Leave'));
      expect(find.byType(FocusScreen), findsNothing);

      await openReady(tester, 'Read the paper');
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(FocusScreen), findsNothing);

      expect(await cycles(tester, db), isEmpty);
      final task = await tester.runAsync(
        () => (db.select(
          db.tasks,
        )..where((t) => t.title.equals('Read the paper'))).getSingle(),
      );
      expect(task!.status, TaskStatus.todo);
    });

    testTomo('Start focusing starts the block with the chosen length, and '
        'remembers it and the project', (tester) async {
      final db = await pumpTomo(
        tester,
        before: someTasks,
        permission: FakePermission(access: (enabled: true, canAsk: true)),
      );
      await openReady(tester, 'Read the paper');
      await tap(tester, find.words('50 min'));
      await tap(tester, button('Start focusing'));

      final cycle = (await cycles(tester, db)).single;
      expect(cycle.focusMinutes, 50);
      expect(cycle.breakMinutes, 10);
      expect(cycle.autoStart, isFalse);
      final task = await tester.runAsync(
        () => (db.select(
          db.tasks,
        )..where((t) => t.id.equals(cycle.taskId))).getSingle(),
      );
      expect(task!.title, 'Read the paper');
      expect(task.status, TaskStatus.doing);

      final settings = container(tester).read(settingsProvider);
      expect(await tester.runAsync(settings.lastFocusMinutes), 50);
      expect(await tester.runAsync(settings.lastBreakMinutes), 10);
      expect(await tester.runAsync(settings.lastProjectId), task.projectId);
      // Running is a stand-in until its own ticket.
      expect(find.byType(LiveFocus), findsOneWidget);
    });
  });

  group('notifications (spec §11.4)', () {
    testTomo('never asked: the framing line; Start asks, then starts', (
      tester,
    ) async {
      final phone = FakePermission();
      final db = await pumpTomo(tester, before: someTasks, permission: phone);
      await openReady(tester, 'Read the paper');

      expect(
        find.words(
          'When a block ends, Tomo can tell you, even with the app closed. '
          'Your phone will ask first.',
        ),
        findsOneWidget,
      );
      expect(iconButton('Notifications are off'), findsNothing);

      await tap(tester, button('Start focusing'));
      expect(phone.asked, 1);
      expect(await cycles(tester, db), hasLength(1));
    });

    testTomo('turned down at the phone\'s question: the block still starts; '
        'the next Ready says so once, and the bell stays', (tester) async {
      final phone = FakePermission()..answer = (granted: false, answered: true);
      final db = await pumpTomo(tester, before: someTasks, permission: phone);
      await openReady(tester, 'Read the paper');
      await tap(tester, button('Start focusing'));
      expect(await cycles(tester, db), hasLength(1));

      // As if the block had been left.
      await tester.runAsync(() => db.delete(db.focusCycle).go());
      Navigator.of(tester.element(find.byType(LiveFocus))).pop();
      await settle(tester);

      const denial =
          "Notifications are off, so Tomo can't tell you when a block ends. "
          'Your blocks still count. The bell at the top opens your phone\'s '
          'settings.';
      await openReady(tester, 'Read the paper');
      expect(find.words(denial), findsOneWidget);
      expect(iconButton('Notifications are off'), findsOneWidget);

      await tap(tester, iconButton('Notifications are off'));
      expect(phone.settingsOpened, 1);

      await tap(tester, iconButton('Leave'));
      await openReady(tester, 'Read the paper');
      expect(find.words(denial), findsNothing);
      expect(iconButton('Notifications are off'), findsOneWidget);
      expect(phone.asked, 1);
    });

    testTomo('allowed: no line and no bell', (tester) async {
      await pumpTomo(
        tester,
        before: someTasks,
        permission: FakePermission(access: (enabled: true, canAsk: true)),
      );
      await openReady(tester, 'Read the paper');

      final middle = find.descendant(
        of: find.byType(ReadyScreen),
        matching: find.byType(PixelText),
      );
      expect(
        [for (final t in tester.widgetList<PixelText>(middle)) t.words],
        [
          'Read the paper',
          'Thesis',
          'Task',
          'Read the paper',
          'Length',
          '25 min',
          '50 min',
          'Custom',
          'Start focusing',
        ],
      );
      expect(iconButton('Notifications are off'), findsNothing);
    });
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/focus/focus_screen.dart';
import 'package:tomo/ui/buttons.dart';
import 'package:tomo/ui/segmented.dart';
import 'package:tomo/ui/stepper.dart';
import 'package:tomo/ui/text_field.dart';
import 'package:tomo/work/project_screen.dart';
import 'package:tomo/work/task_detail_screen.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_service.dart';
import 'package:tomo_core/tasks/task_status.dart';

import '../app/app_harness.dart';
import '../ui/kit_harness.dart';

/// Task detail (spec §8.8): the fields, saving as you go, the project row
/// and its sheet, the status control, the planned-blocks stepper, Focus so
/// far, the three variants of the button, and the task lock's lines where
/// the tap happened. Promise 13 (the lock, on screen).
void main() {
  late TomoDatabase db;

  T ok<T>(Result<T> result) => (result as Success<T>).value;
  TaskService service(TomoDatabase db) =>
      TaskService(db, log: Log(sinks: const []));

  /// Lets the database's work finish on the real clock, then hands the app
  /// what changed.
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

  Future<void> tap(WidgetTester tester, Finder finder) async {
    // At large text the screen scrolls to it first.
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await settle(tester);
    await settle(tester);
  }

  /// A task in [project], with [blocks] finished blocks of 25 minutes.
  Future<void> add(
    TomoDatabase db,
    String title, {
    TaskStatus status = TaskStatus.todo,
    int blocks = 0,
    int? planned,
    String? notes,
    String project = 'Things',
  }) async {
    final tasks = service(db);
    final into = (await tasks.projects()).firstWhere((p) => p.name == project);
    final task = ok(
      await tasks.createTask(
        projectId: into.id,
        title: title,
        notes: notes,
        estimate: planned,
      ),
    );
    if (blocks > 0) {
      await db.customStatement(
        'UPDATE tasks SET actual_pomodoros = ?, cumulative_focus_minutes = ? '
        'WHERE id = ?',
        [blocks, blocks * 25, task.id],
      );
    }
    if (status != TaskStatus.todo) {
      ok(await tasks.updateTask(task.id, TaskPatch(status: status)));
    }
  }

  /// Opens the app on the Work tab, then Things, then the task [title].
  /// The harness's onboarding made the project **Things**.
  Future<void> openTask(
    WidgetTester tester,
    String title, {
    Future<void> Function(TomoDatabase db)? before,
    double textScale = 1,
    ThemeName theme = ThemeName.light,
  }) async {
    db = await pumpTomo(
      tester,
      before: before,
      textScale: textScale,
      theme: theme,
    );
    // A live cycle opens Focus at a cold start: minimise it.
    if (find.byType(FocusScreen).evaluate().isNotEmpty) {
      await tester.binding.handlePopRoute();
      await settle(tester);
    }
    await tap(tester, find.words('Work'));
    await tap(tester, find.words('Things'));
    // The banner may name the task too.
    await tap(
      tester,
      find.descendant(
        of: find.byType(ProjectScreen),
        matching: find.words(title),
      ),
    );
  }

  Future<TaskRow?> read(WidgetTester tester, String title) async =>
      tester.runAsync<TaskRow?>(
        () async => (await db.select(db.tasks).get())
            .where((row) => row.title == title)
            .firstOrNull,
      );

  Future<int> petExp(WidgetTester tester) async =>
      (await tester.runAsync(() => db.select(db.pets).getSingle()))!.exp;

  Finder onDetail(Finder finder) =>
      find.descendant(of: find.byType(TaskDetailScreen), matching: finder);

  Finder button(String label) => onDetail(
    find.ancestor(of: find.words(label), matching: find.byType(PixelButton)),
  );

  Finder titleField() => onDetail(find.byType(PixelTextField)).first;
  Finder notesField() => onDetail(find.byType(PixelTextField)).last;

  TaskStatus shownStatus(WidgetTester tester) => tester
      .widget<PixelSegmented<TaskStatus>>(
        onDetail(find.byType(PixelSegmented<TaskStatus>)),
      )
      .selected;

  PixelStepper stepper(WidgetTester tester) =>
      tester.widget(onDetail(find.byType(PixelStepper)));

  Finder segment(String label) => onDetail(
    find.descendant(
      of: find.byType(PixelSegmented<TaskStatus>),
      matching: find.words(label),
    ),
  );

  /// Leaves the field being typed in, as tapping elsewhere does.
  Future<void> leaveField(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await settle(tester);
  }

  const lockLine =
      'A block is running on this task. Stop it or let it finish first.';

  testTomo('shows every field, top to bottom, for a new task', (tester) async {
    await openTask(
      tester,
      'Read the paper',
      before: (db) => add(db, 'Read the paper'),
    );

    expect(find.byType(TaskDetailScreen).hitTestable(), findsOneWidget);
    final title = tester.widget<PixelTextField>(titleField());
    expect(title.controller.text, 'Read the paper');
    expect(onDetail(find.words('Add notes')), findsOneWidget);
    expect(onDetail(find.words('Project')), findsOneWidget);
    expect(onDetail(find.words('Things')), findsOneWidget);
    expect(shownStatus(tester), TaskStatus.todo);
    expect(stepper(tester).value, 'No plan');
    expect(stepper(tester).onLess, isNull);
    expect(onDetail(find.words('None yet')), findsOneWidget);
    expect(button('Start focusing'), findsOneWidget);
    expect(button('Delete task'), findsOneWidget);

    // Top to bottom, as Tomo Task Screens has them.
    double top(Finder f) => tester.getTopLeft(f).dy;
    expect(top(titleField()), lessThan(top(notesField())));
    expect(top(notesField()), lessThan(top(onDetail(find.words('Project')))));
    expect(
      top(onDetail(find.words('Project'))),
      lessThan(top(onDetail(find.words('Status')))),
    );
    expect(
      top(onDetail(find.words('Status'))),
      lessThan(top(onDetail(find.words('Planned blocks')))),
    );
    expect(
      top(onDetail(find.words('Planned blocks'))),
      lessThan(top(onDetail(find.words('Focus so far')))),
    );
    expect(
      top(onDetail(find.words('Focus so far'))),
      lessThan(top(button('Start focusing'))),
    );
    expect(top(button('Start focusing')), lessThan(top(button('Delete task'))));
  });

  testTomo('Focus so far counts the blocks and their time', (tester) async {
    await openTask(
      tester,
      'Write the intro',
      before: (db) =>
          add(db, 'Write the intro', status: TaskStatus.doing, blocks: 2),
    );

    expect(onDetail(find.words('2 blocks · 50 min')), findsOneWidget);
    expect(shownStatus(tester), TaskStatus.doing);
  });

  group('typing saves as you go', () {
    testTomo('a new title is kept when you leave the field', (tester) async {
      await openTask(tester, 'Read', before: (db) => add(db, 'Read'));

      await tester.enterText(titleField(), 'Read the Kowalski paper');
      await leaveField(tester);

      expect(await read(tester, 'Read the Kowalski paper'), isNotNull);
      expect(await read(tester, 'Read'), isNull);
    });

    testTomo('a title cleared away keeps the old one', (tester) async {
      await openTask(tester, 'Read', before: (db) => add(db, 'Read'));

      await tester.enterText(titleField(), '   ');
      await leaveField(tester);

      expect(await read(tester, 'Read'), isNotNull);
      expect(
        tester.widget<PixelTextField>(titleField()).controller.text,
        'Read',
      );
    });

    testTomo('a title takes no new line', (tester) async {
      await openTask(tester, 'Read', before: (db) => add(db, 'Read'));

      await tester.enterText(titleField(), 'Read\nthe paper');
      await leaveField(tester);

      expect(await read(tester, 'Readthe paper'), isNotNull);
    });

    testTomo('notes are kept when you leave the field, and blank clears them', (
      tester,
    ) async {
      await openTask(tester, 'Read', before: (db) => add(db, 'Read'));

      await tester.enterText(notesField(), 'Chapters 2 and 3.');
      await leaveField(tester);
      expect((await read(tester, 'Read'))!.notes, 'Chapters 2 and 3.');

      await tester.enterText(notesField(), '  ');
      await leaveField(tester);
      expect((await read(tester, 'Read'))!.notes, isNull);
    });

    testTomo('typing and going straight back still keeps the words', (
      tester,
    ) async {
      await openTask(tester, 'Read', before: (db) => add(db, 'Read'));

      await tester.enterText(notesField(), 'The library copy is on hold.');
      await tester.binding.handlePopRoute();
      await settle(tester);

      expect(find.byType(ProjectScreen).hitTestable(), findsOneWidget);
      expect(
        (await read(tester, 'Read'))!.notes,
        'The library copy is on hold.',
      );
    });
  });

  testTomo('the project row moves the task, which stays open', (tester) async {
    await openTask(
      tester,
      'Read',
      before: (db) async {
        ok(await service(db).createProject('Thesis'));
        await add(db, 'Read');
      },
    );

    await tap(tester, onDetail(find.words('Things')));
    expect(find.words('Move to project'), findsOneWidget);
    await tap(tester, find.words('Thesis'));

    final thesis = (await tester.runAsync(
      () async =>
          (await service(db).projects()).firstWhere((p) => p.name == 'Thesis'),
    ))!;
    expect((await read(tester, 'Read'))!.projectId, thesis.id);
    expect(find.byType(TaskDetailScreen).hitTestable(), findsOneWidget);
    expect(onDetail(find.words('Thesis')), findsOneWidget);
  });

  group('the status control', () {
    testTomo('sets doing, and done, paying the bonus quietly', (tester) async {
      await openTask(
        tester,
        'Write',
        before: (db) => add(db, 'Write', blocks: 2),
      );
      final before = await petExp(tester);

      await tap(tester, segment('Doing'));
      expect((await read(tester, 'Write'))!.status, TaskStatus.doing);
      expect(shownStatus(tester), TaskStatus.doing);

      await tap(tester, segment('Done'));
      expect((await read(tester, 'Write'))!.status, TaskStatus.done);
      expect(await petExp(tester), before + 50);
      expect(shownStatus(tester), TaskStatus.done);
    });

    testTomo('a done task shows the done-task line, not Start focusing', (
      tester,
    ) async {
      await openTask(
        tester,
        'Write',
        before: (db) => add(db, 'Write', status: TaskStatus.done),
      );

      expect(button('Start focusing'), findsNothing);
      expect(
        onDetail(find.words('To focus on this again, set it back to To do.')),
        findsOneWidget,
      );

      await tap(tester, segment('To do'));
      expect(button('Start focusing'), findsOneWidget);
    });
  });

  testTomo('planned blocks: + from no plan is 1, − from 1 is no plan, '
      'and + stops at 20', (tester) async {
    await openTask(tester, 'Write', before: (db) => add(db, 'Write'));

    await tap(tester, onDetail(find.bySemanticsLabel('More')));
    expect((await read(tester, 'Write'))!.estimatedPomodoros, 1);
    expect(stepper(tester).value, '1 block');

    await tap(tester, onDetail(find.bySemanticsLabel('More')));
    expect(stepper(tester).value, '2 blocks');

    await tap(tester, onDetail(find.bySemanticsLabel('Fewer')));
    await tap(tester, onDetail(find.bySemanticsLabel('Fewer')));
    expect((await read(tester, 'Write'))!.estimatedPomodoros, isNull);
    expect(stepper(tester).value, 'No plan');
    expect(stepper(tester).onLess, isNull);

    await tester.runAsync(
      () => db.customStatement("UPDATE tasks SET estimated_pomodoros = 20"),
    );
    await settle(tester);
    expect(stepper(tester).value, '20 blocks');
    expect(stepper(tester).onMore, isNull);
  });

  testTomo('Start focusing opens Focus on Ready, on this task', (tester) async {
    await openTask(tester, 'Write', before: (db) => add(db, 'Write'));

    await tap(tester, button('Start focusing'));

    expect(find.byType(ReadyScreen), findsOneWidget);
    expect(
      tester.widget<ReadyScreen>(find.byType(ReadyScreen)).picked.task.title,
      'Write',
    );
  });

  group('while its block runs', () {
    testTomo('the button is Back to focus, which opens Focus', (tester) async {
      await openTask(
        tester,
        'Write the intro',
        before: (db) => startBlockOn(db),
      );

      expect(button('Start focusing'), findsNothing);
      await tap(tester, button('Back to focus'));
      expect(find.byType(FocusScreen), findsOneWidget);
      expect(find.byType(ReadyScreen), findsNothing);
    });

    testTomo('Done is refused under the status control', (tester) async {
      await openTask(
        tester,
        'Write the intro',
        before: (db) => startBlockOn(db),
      );

      await tap(tester, segment('Done'));

      expect(shownStatus(tester), TaskStatus.doing);
      expect((await read(tester, 'Write the intro'))!.status, TaskStatus.doing);
      final line = onDetail(find.words(lockLine));
      expect(line, findsOneWidget);
      expect(
        tester.getTopLeft(line).dy,
        greaterThan(tester.getTopLeft(segment('Done')).dy),
      );
      expect(
        tester.getTopLeft(line).dy,
        lessThan(tester.getTopLeft(onDetail(find.words('Planned blocks'))).dy),
      );

      // It goes at the next touch.
      await tester.tapAt(const Offset(10, 300));
      await settle(tester);
      expect(onDetail(find.words(lockLine)), findsNothing);
    });

    testTomo('Delete task is refused at once, under it', (tester) async {
      await openTask(
        tester,
        'Write the intro',
        before: (db) => startBlockOn(db),
      );

      await tap(tester, button('Delete task'));

      expect(find.words('Delete this task?'), findsNothing);
      expect(onDetail(find.words(lockLine)), findsOneWidget);
      expect(
        tester.getTopLeft(onDetail(find.words(lockLine))).dy,
        greaterThan(tester.getTopLeft(button('Delete task')).dy),
      );
      expect(await read(tester, 'Write the intro'), isNotNull);
    });
  });

  testTomo('while another task\'s block runs, Start focusing is off, '
      'with the line naming that task', (tester) async {
    await openTask(
      tester,
      'Read',
      before: (db) async {
        await startBlockOn(db);
        await add(db, 'Read');
      },
    );

    final start = tester.widget<PixelButton>(button('Start focusing'));
    expect(start.onPressed, isNull);
    expect(
      onDetail(
        find.words(
          'A block is running on "Write the intro". Stop it or let it '
          'finish first.',
        ),
      ),
      findsOneWidget,
    );
  });

  testTomo('Delete task asks, then deletes and goes back to the project', (
    tester,
  ) async {
    await openTask(
      tester,
      'Write',
      before: (db) => add(db, 'Write', blocks: 1),
    );

    await tap(tester, button('Delete task'));
    expect(find.words('Delete this task?'), findsOneWidget);
    expect(
      find.words(
        '"Write" and its notes go for good. The 25 minutes you focused on it '
        'stay in your stats.',
      ),
      findsOneWidget,
    );
    await tap(
      tester,
      find
          .ancestor(
            of: find.words('Delete task'),
            matching: find.byType(PixelButton),
          )
          .last,
    );

    expect(await read(tester, 'Write'), isNull);
    expect(find.byType(TaskDetailScreen), findsNothing);
    expect(find.byType(ProjectScreen).hitTestable(), findsOneWidget);
  });

  group('at 200% text', () {
    for (final theme in ThemeName.values) {
      testTomo('nothing overflows, ${theme.name}', (tester) async {
        await openTask(
          tester,
          'Email Łukasz about the second draft of chapter two',
          textScale: 2,
          theme: theme,
          before: (db) async {
            await startBlockOn(db);
            await add(
              db,
              'Email Łukasz about the second draft of chapter two',
              status: TaskStatus.doing,
              blocks: 5,
              planned: 4,
              notes: 'Chapters 2 and 3. The library copy is on hold.',
            );
          },
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(button('Delete task'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });
}

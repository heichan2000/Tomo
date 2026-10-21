import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/shell.dart';
import 'package:tomo/app/tomo_look.dart';
import 'package:tomo/focus/focus_screen.dart';
import 'package:tomo/ui/buttons.dart';
import 'package:tomo/ui/pixel_icon.dart';
import 'package:tomo/ui/rows.dart';
import 'package:tomo/ui/segmented.dart';
import 'package:tomo/ui/text_field.dart';
import 'package:tomo/work/project_screen.dart';
import 'package:tomo/work/task_detail_screen.dart';
import 'package:tomo/work/task_list_row.dart';
import 'package:tomo/work/work_screen.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_service.dart';
import 'package:tomo_core/tasks/task_status.dart';

import '../app/app_harness.dart';
import '../ui/kit_harness.dart';

/// The Work tab and a project's screen (spec §8.8): the project rows and
/// their counts, *New project*, the task list in its order, the quiet mark
/// done, *Add a task*, the row and project menus, the task lock's lines
/// where the tap happened, the deletes, and the empty and all-done states.
/// Promises 41 (the ring's half) and 13 (the lock, on screen).
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

  Future<void> longPress(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.longPress(finder);
    await settle(tester);
  }

  Finder tabWords(String label) => find.descendant(
    of: find.byType(ShellTabBar),
    matching: find.words(label),
  );

  /// Opens the app on the Work tab. The harness's onboarding made the
  /// project **Things**; [before] can add more, or start a block.
  Future<void> openWork(
    WidgetTester tester, {
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
    await tap(tester, tabWords('Work'));
  }

  /// Opens the app straight onto Things' screen.
  Future<void> openProject(
    WidgetTester tester, {
    Future<void> Function(TomoDatabase db)? before,
    double textScale = 1,
    ThemeName theme = ThemeName.light,
  }) async {
    await openWork(tester, before: before, textScale: textScale, theme: theme);
    await tap(tester, find.words('Things'));
  }

  Future<Project> things(TomoDatabase db) async =>
      (await service(db).projects()).firstWhere((p) => p.name == 'Things');

  Future<TaskRow?> rowNamed(TomoDatabase db, String title) async =>
      (await db.select(db.tasks).get())
          .where((row) => row.title == title)
          .firstOrNull;

  /// A task in [project], with [blocks] finished blocks of 25 minutes.
  Future<void> add(
    TomoDatabase db,
    String title, {
    TaskStatus status = TaskStatus.todo,
    int blocks = 0,
    int? planned,
    String project = 'Things',
  }) async {
    final tasks = service(db);
    final into = (await tasks.projects()).firstWhere((p) => p.name == project);
    final task = ok(
      await tasks.createTask(
        projectId: into.id,
        title: title,
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

  Future<TaskRow?> read(WidgetTester tester, String title) async =>
      tester.runAsync<TaskRow?>(() => rowNamed(db, title));

  Future<int> petExp(WidgetTester tester) async =>
      (await tester.runAsync(() => db.select(db.pets).getSingle()))!.exp;

  List<String> rowTitles(WidgetTester tester) => [
    for (final row in tester.widgetList<TaskListRow>(find.byType(TaskListRow)))
      row.task.title,
  ];

  Finder rowOf(String title) =>
      find.ancestor(of: find.words(title), matching: find.byType(TaskListRow));

  PixelRow pixelRow(WidgetTester tester, String title) => tester.widget(
    find.descendant(of: rowOf(title), matching: find.byType(PixelRow)),
  );

  Finder ring(String title) => find
      .descendant(of: rowOf(title), matching: find.byType(PixelIconButton))
      .first;

  Finder more(String title) => find
      .descendant(of: rowOf(title), matching: find.byType(PixelIconButton))
      .last;

  Finder iconButton(String label) => find.byWidgetPredicate(
    (widget) => widget is PixelIconButton && widget.semanticLabel == label,
  );

  Finder button(String label) =>
      find.ancestor(of: find.words(label), matching: find.byType(PixelButton));

  TaskStatus shownStatus(WidgetTester tester, String title) => tester
      .widget<StatusGlyph>(
        find.descendant(of: rowOf(title), matching: find.byType(StatusGlyph)),
      )
      .status;

  List<PixelChip> chips(WidgetTester tester, String title) => tester
      .widgetList<PixelChip>(
        find.descendant(of: rowOf(title), matching: find.byType(PixelChip)),
      )
      .toList();

  const lockLine =
      'A block is running on this task. Stop it or let it finish first.';

  group('the Work tab', () {
    testTomo('each project with its tasks counted, the most recent first', (
      tester,
    ) async {
      await openWork(
        tester,
        before: (db) async {
          await add(db, 'Read', status: TaskStatus.done);
          await add(db, 'Write');
          await add(db, 'Edit', status: TaskStatus.doing);
          ok(await service(db).createProject('Moving flat'));
          await add(
            db,
            'Pack',
            project: 'Moving flat',
            status: TaskStatus.done,
          );
          ok(await service(db).createProject('Spanish'));
        },
      );

      // The title, and the tab.
      expect(find.words('Work'), findsNWidgets(2));
      final rows = [
        for (final row in tester.widgetList<PixelRow>(find.byType(PixelRow)))
          (row.title, row.subtitle),
      ];
      expect(rows, [
        ('Spanish', 'No tasks'),
        ('Moving flat', 'All 1 done'),
        ('Things', '2 open · 1 done'),
      ]);
    });

    testTomo('a project row opens the project', (tester) async {
      await openWork(tester);

      await tap(tester, find.words('Things'));

      expect(find.byType(ProjectScreen).hitTestable(), findsOneWidget);
    });

    testTomo('+ makes a new project and opens it', (tester) async {
      await openWork(tester);

      await tap(tester, iconButton('New project'));
      expect(find.words('New project'), findsOneWidget);
      final create = tester.widget<PixelButton>(button('Create project'));
      expect(create.onPressed, isNull, reason: 'off until a name is typed');

      await tester.enterText(find.byType(PixelTextField), '  Spanish ');
      await tester.pump();
      await tap(tester, button('Create project'));

      expect(find.byType(ProjectScreen).hitTestable(), findsOneWidget);
      expect(find.words('Nothing in Spanish yet'), findsOneWidget);
      final projects = await tester.runAsync(() => service(db).projects());
      expect([for (final p in projects!) p.name], ['Spanish', 'Things']);
    });

    testTomo('with no projects left, a card offers a new one', (tester) async {
      await openWork(
        tester,
        before: (db) async =>
            ok(await service(db).deleteProject((await things(db)).id)),
      );

      expect(find.words('No projects yet'), findsOneWidget);
      expect(
        find.words(
          'A project holds the tasks for one piece of work, like a thesis or '
          'a move.',
        ),
        findsOneWidget,
      );
      final icon = tester.widget<PixelIcon>(
        find.descendant(
          of: find.byType(EmptyCard),
          matching: find.byType(PixelIcon),
        ),
      );
      expect(icon.scale, 2);
      await tap(tester, button('New project'));
      expect(find.byType(PixelTextField), findsOneWidget);
    });
  });

  group("a project's tasks", () {
    testTomo('doing, then to do, then done greyed at the bottom, each with '
        'its blocks in words', (tester) async {
      await openProject(
        tester,
        before: (db) async {
          await add(db, 'Find a supervisor', status: TaskStatus.done);
          await add(
            db,
            'Collect sources',
            status: TaskStatus.done,
            blocks: 5,
            planned: 4,
          );
          await add(db, 'Read the paper', planned: 2);
          await add(db, 'Email the draft', blocks: 1);
          await add(
            db,
            'Write the intro',
            status: TaskStatus.doing,
            blocks: 2,
            planned: 4,
          );
        },
      );

      expect(rowTitles(tester), [
        'Write the intro',
        'Email the draft',
        'Read the paper',
        'Collect sources',
        'Find a supervisor',
      ]);
      expect(pixelRow(tester, 'Write the intro').subtitle, '2 of 4 blocks');
      expect(pixelRow(tester, 'Email the draft').subtitle, '1 block');
      expect(pixelRow(tester, 'Read the paper').subtitle, '0 of 2 blocks');
      expect(
        pixelRow(tester, 'Collect sources').subtitle,
        '5 blocks · planned 4',
      );
      expect(pixelRow(tester, 'Find a supervisor').subtitle, isNull);

      expect(pixelRow(tester, 'Collect sources').mutedTitle, isTrue);
      expect(pixelRow(tester, 'Read the paper').mutedTitle, isFalse);
      expect(
        [for (final c in chips(tester, 'Write the intro')) c.label],
        ['Doing'],
      );
      expect(chips(tester, 'Read the paper'), isEmpty);
      expect(find.words('3 open · 2 done'), findsOneWidget);

      // The add field sits at the end of the open tasks.
      final field = tester.getRect(find.byType(PixelTextField));
      expect(
        field.top,
        greaterThan(tester.getRect(rowOf('Read the paper')).bottom),
      );
      expect(
        field.bottom,
        lessThan(tester.getRect(rowOf('Collect sources')).top),
      );
    });

    testTomo('the running task wears the accent Focus chip', (tester) async {
      await openProject(tester, before: (db) => startBlockOn(db));

      final chip = chips(tester, 'Write the intro').single;
      expect(chip.label, 'Focus');
      expect(chip.tone, ChipTone.accent);
    });

    testTomo('a row opens the task', (tester) async {
      await openProject(tester, before: (db) => add(db, 'Read the paper'));

      await tap(tester, find.words('Read the paper'));

      expect(find.byType(TaskDetailScreen).hitTestable(), findsOneWidget);
    });
  });

  group('tapping the ring', () {
    testTomo('marks the task done at once, and the row moves after a '
        'moment, quietly, with the bonus paid', (tester) async {
      await openProject(
        tester,
        before: (db) async {
          await add(db, 'Collect sources', status: TaskStatus.done);
          await add(db, 'Read the paper');
          await add(db, 'Email the draft', blocks: 1);
        },
      );
      final before = await petExp(tester);
      expect(rowTitles(tester), [
        'Email the draft',
        'Read the paper',
        'Collect sources',
      ]);

      await tester.tap(ring('Email the draft'));
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
        );
        await tester.pump();
      }
      await petChanged(tester, db);

      // The ring has filled where the row is.
      expect(shownStatus(tester, 'Email the draft'), TaskStatus.done);
      expect(rowTitles(tester).first, 'Email the draft');

      await tester.pump(const Duration(milliseconds: 440));
      expect(rowTitles(tester).first, 'Email the draft');
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();

      expect(rowTitles(tester), [
        'Read the paper',
        'Email the draft',
        'Collect sources',
      ]);
      expect((await read(tester, 'Email the draft'))!.status, TaskStatus.done);
      // 25 minutes of focus: 25 EXP, paid but never shown here.
      expect(await petExp(tester), before + 25);
      expect(find.words('+25 EXP'), findsNothing);
      expect(find.byType(SunkenLine), findsNothing);
    });

    testTomo('on a done task reopens it: doing if it has blocks, else to do', (
      tester,
    ) async {
      await openProject(
        tester,
        before: (db) async {
          await add(db, 'Never focused', status: TaskStatus.done);
          await add(db, 'Focused', status: TaskStatus.done, blocks: 2);
        },
      );

      await tap(tester, ring('Focused'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await tap(tester, ring('Never focused'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect((await read(tester, 'Focused'))!.status, TaskStatus.doing);
      expect((await read(tester, 'Never focused'))!.status, TaskStatus.todo);
      expect(rowTitles(tester), ['Focused', 'Never focused']);
      expect([for (final c in chips(tester, 'Focused')) c.label], ['Doing']);
    });

    testTomo('on the running task is refused under the row, and the ring '
        'does not change', (tester) async {
      await openProject(tester, before: (db) => startBlockOn(db));

      await tap(tester, ring('Write the intro'));

      expect(shownStatus(tester, 'Write the intro'), TaskStatus.doing);
      expect((await read(tester, 'Write the intro'))!.status, TaskStatus.doing);
      final line = find.words(lockLine);
      expect(line, findsOneWidget);
      expect(
        tester.getRect(line).top,
        greaterThan(tester.getRect(rowOf('Write the intro')).bottom),
      );

      // It goes at the next touch.
      await tester.tapAt(const Offset(200, 700));
      await tester.pump();
      expect(line, findsNothing);
    });
  });

  group('adding a task', () {
    testTomo('Enter adds it as to do and keeps the field ready', (
      tester,
    ) async {
      await openProject(tester, before: (db) => add(db, 'Read the paper'));

      await tester.tap(find.byType(PixelTextField));
      await tester.pump();
      await tester.enterText(find.byType(PixelTextField), 'Book a room');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);

      expect(rowTitles(tester), ['Book a room', 'Read the paper']);
      expect((await read(tester, 'Book a room'))!.status, TaskStatus.todo);
      final field = tester.widget<PixelTextField>(find.byType(PixelTextField));
      expect(field.controller.text, isEmpty);
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.enterText(find.byType(PixelTextField), 'Call the library');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
      expect(rowTitles(tester), [
        'Call the library',
        'Book a room',
        'Read the paper',
      ]);
    });

    testTomo('a project with no tasks shows a card, then the field', (
      tester,
    ) async {
      await openProject(tester);

      expect(find.words('Nothing in Things yet'), findsOneWidget);
      expect(
        find.words(
          'Add the first task. You can focus on it from here or from Home.',
        ),
        findsOneWidget,
      );
      // The field is the card's action.
      expect(find.byType(PixelButton), findsNothing);

      await tester.tap(find.byType(PixelTextField));
      await tester.pump();
      await tester.enterText(find.byType(PixelTextField), 'First');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);

      expect(find.words('Nothing in Things yet'), findsNothing);
      expect(rowTitles(tester), ['First']);
      expect(tester.testTextInput.isVisible, isTrue);
    });
  });

  testTomo('when every task is done, a sunken line says so above them', (
    tester,
  ) async {
    await openProject(
      tester,
      before: (db) => add(db, 'Read the paper', status: TaskStatus.done),
    );

    final line = find.words('Everything in Things is done.');
    expect(line, findsOneWidget);
    expect(
      tester.getRect(line).bottom,
      lessThan(tester.getRect(rowOf('Read the paper')).top),
    );
    expect(find.words('All 1 done'), findsOneWidget);
    expect(find.byType(PixelTextField), findsOneWidget);
  });

  group('the row menu', () {
    testTomo('opens from ⋯ or a long press, and sets any status', (
      tester,
    ) async {
      await openProject(tester, before: (db) => add(db, 'Read the paper'));

      await longPress(tester, find.words('Read the paper'));
      expect(find.byType(PixelSegmented<TaskStatus>), findsOneWidget);
      expect(find.words('Move to another project'), findsOneWidget);
      expect(find.words('Delete task'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await settle(tester);
      expect(find.byType(PixelSegmented<TaskStatus>), findsNothing);

      await tap(tester, more('Read the paper'));
      await tap(tester, find.words('Doing'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(PixelSegmented<TaskStatus>), findsNothing);
      expect((await read(tester, 'Read the paper'))!.status, TaskStatus.doing);
      expect(
        [for (final c in chips(tester, 'Read the paper')) c.label],
        ['Doing'],
      );
    });

    testTomo('refuses Done on the running task under the status control', (
      tester,
    ) async {
      await openProject(tester, before: (db) => startBlockOn(db));

      await tap(tester, more('Write the intro'));
      await tap(
        tester,
        find.descendant(
          of: find.byType(PixelSegmented<TaskStatus>),
          matching: find.words('Done'),
        ),
      );

      expect(find.words(lockLine), findsOneWidget);
      expect(find.byType(PixelSegmented<TaskStatus>), findsOneWidget);
      expect((await read(tester, 'Write the intro'))!.status, TaskStatus.doing);
    });

    testTomo('moves the task to another project', (tester) async {
      await openProject(
        tester,
        before: (db) async {
          ok(await service(db).createProject('Spanish'));
          await add(db, 'Read the paper');
        },
      );

      await tap(tester, more('Read the paper'));
      await tap(tester, find.words('Move to another project'));
      expect(find.words('Move to project'), findsOneWidget);
      await tap(tester, find.words('Spanish'));

      expect(rowTitles(tester), isEmpty);
      final moved = (await read(tester, 'Read the paper'))!;
      final spanish = await tester.runAsync(
        () async => (await service(
          db,
        ).projects()).firstWhere((p) => p.name == 'Spanish'),
      );
      expect(moved.projectId, spanish!.id);
    });

    testTomo('deletes the task after asking, saying the focus time stays', (
      tester,
    ) async {
      await openProject(
        tester,
        before: (db) => add(db, 'Email the draft', blocks: 1),
      );

      await tap(tester, more('Email the draft'));
      await tap(tester, find.words('Delete task'));
      expect(find.words('Delete this task?'), findsOneWidget);
      expect(
        find.words(
          '"Email the draft" and its notes go for good. The 25 minutes you '
          'focused on it stay in your stats.',
        ),
        findsOneWidget,
      );
      expect(
        tester.getRect(button('Cancel')).bottom,
        lessThan(tester.getRect(button('Delete task')).top),
      );

      await tap(tester, button('Cancel'));
      expect(await read(tester, 'Email the draft'), isNotNull);

      await tap(tester, more('Email the draft'));
      await tap(tester, find.words('Delete task'));
      await tap(tester, button('Delete task'));

      expect(await read(tester, 'Email the draft'), isNull);
      expect(rowTitles(tester), isEmpty);
    });

    testTomo('refuses to delete the running task, without asking', (
      tester,
    ) async {
      await openProject(tester, before: (db) => startBlockOn(db));

      await tap(tester, more('Write the intro'));
      await tap(tester, find.words('Delete task'));

      expect(find.words('Delete this task?'), findsNothing);
      expect(find.words(lockLine), findsOneWidget);
    });
  });

  group('the project menu', () {
    testTomo('renames the project', (tester) async {
      await openProject(tester);

      await tap(tester, iconButton('Project options'));
      await tap(tester, find.words('Rename project'));
      // The sheet's field, over the project's own.
      final named = find.byType(PixelTextField).last;
      expect(tester.widget<PixelTextField>(named).controller.text, 'Things');
      await tester.enterText(named, 'Thesis');
      await tester.pump();
      await tap(tester, button('Rename'));

      expect(find.words('Thesis'), findsOneWidget);
      final projects = await tester.runAsync(() => service(db).projects());
      expect(projects!.single.name, 'Thesis');
    });

    testTomo('deletes the project after asking, and goes back to Work', (
      tester,
    ) async {
      await openProject(
        tester,
        before: (db) async {
          await add(db, 'Write the intro', blocks: 10);
          await add(db, 'Read the paper', blocks: 6);
        },
      );

      await tap(tester, iconButton('Project options'));
      await tap(tester, find.words('Delete project'));
      expect(find.words('Delete "Things"?'), findsOneWidget);
      expect(
        find.words(
          'Its 2 tasks go with it, for good. The 6 h 40 min you focused on '
          'them stays in your stats.',
        ),
        findsOneWidget,
      );
      await tap(tester, button('Delete project'));

      expect(find.byType(ProjectScreen), findsNothing);
      expect(find.byType(WorkScreen).hitTestable(), findsOneWidget);
      expect(find.words('No projects yet'), findsOneWidget);
    });

    testTomo('refuses to delete it while one of its tasks is running', (
      tester,
    ) async {
      await openProject(tester, before: (db) => startBlockOn(db));

      await tap(tester, iconButton('Project options'));
      await tap(tester, find.words('Delete project'));

      expect(find.words('Delete "Things"?'), findsNothing);
      expect(
        find.words(
          'A block is running on a task in this project. Stop it or let it '
          'finish first.',
        ),
        findsOneWidget,
      );
    });
  });

  testTomo('under reduce motion the row jumps to its place', (tester) async {
    await openProject(
      tester,
      before: (db) async {
        await add(db, 'Read the paper');
        await add(db, 'Email the draft');
      },
    );
    lookOverride.value = const LookOverride(
      theme: ThemeName.light,
      reduceMotion: true,
    );
    await tester.pumpAndSettle();

    await tap(tester, ring('Email the draft'));
    await tester.pump(const Duration(milliseconds: 460));

    expect(rowTitles(tester), ['Read the paper', 'Email the draft']);
    expect(tester.hasRunningAnimations, isFalse);
  });

  group('the keyboard', () {
    testTomo('typing a task scrolls nothing when the list fits', (
      tester,
    ) async {
      await openProject(
        tester,
        before: (db) async {
          await add(db, 'One');
          await add(db, 'Two');
        },
      );

      tester.view.viewInsets = const FakeViewPadding(bottom: 1100);
      addTearDown(tester.view.resetViewInsets);
      await tester.tap(find.byType(PixelTextField));
      await tester.pumpAndSettle();

      final scroll = find.descendant(
        of: find.byType(ProjectScreen),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scroll.first).position;
      expect(position.maxScrollExtent, 0);
      expect(position.pixels, 0);
    });
  });
}

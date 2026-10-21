import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/providers.dart';
import 'package:tomo/app/running_banner.dart';
import 'package:tomo/app/shell.dart';
import 'package:tomo/focus/focus_screen.dart';
import 'package:tomo/home/home_screen.dart';
import 'package:tomo/ui/buttons.dart';
import 'package:tomo/ui/rows.dart';
import 'package:tomo/ui/sharp_text.dart';
import 'package:tomo/work/task_list_row.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_service.dart';
import 'package:tomo_core/tasks/task_status.dart';
import 'package:tomo_core/testing.dart';

import 'app/app_harness.dart';
import 'platform/fake_notifications.dart';
import 'ui/kit_harness.dart';

/// Every route together (spec §12, §10.4): the app walked from onboarding to
/// the hatch and through every screen, sheet and Focus state, with long
/// words in it. At each stop nothing overflows, every tappable part is at
/// least 48 pt and labelled, the screen's title is a header, nothing is a
/// live region, and nothing is read twice in a row. Walked at 100% and at
/// 200% text, in both themes, on three screens.
///
/// Promises 31 (every route at 200%) and 32 (no live region; the pet one
/// item, on every screen). What a screen reader says in each state is held
/// by each screen's own tests.
void main() {
  // Every walk starts at nine.
  final nine = DateTime.utc(2026, 10, 18, 9);
  DateTime at(int minute) => nine.add(Duration(minutes: minute));

  late TestClock clock;
  late TomoDatabase db;
  final log = Log(sinks: const []);
  T ok<T>(Result<T> result) => (result as Success<T>).value;

  const long = 'Email Łukasz about the second draft of chapter two';

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
    // What the tap wrote reaches the screen.
    await settle(tester);
  }

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await settle(tester);
  }

  Future<void> passTo(WidgetTester tester, int minute) async {
    final by = at(minute).difference(clock.now);
    clock.now = at(minute);
    await tester.pump(by);
    await settle(tester);
  }

  Finder button(String label) =>
      find.ancestor(of: find.words(label), matching: find.byType(PixelButton));
  Finder iconButton(String label) => find.byWidgetPredicate(
    (widget) => widget is PixelIconButton && widget.semanticLabel == label,
  );
  Finder row(String title) => find
      .ancestor(of: find.words(title), matching: find.byType(PixelRow))
      .first;
  Finder tab(String label) => find.descendant(
    of: find.byType(ShellTabBar),
    matching: find.words(label),
  );
  Finder rowMenu(String title) => find
      .descendant(
        of: find.ancestor(
          of: find.words(title),
          matching: find.byType(TaskListRow),
        ),
        matching: find.byType(PixelIconButton),
      )
      .last;
  Finder saying(String part) => find.byWidgetPredicate(
    (widget) => widget is PixelText && widget.words.contains(part),
  );
  Finder banner() => find.descendant(
    of: find.byType(RunningBannerSlot),
    matching: find.byType(Pressable),
  );

  /// The screen reader's items, in the order it reads them.
  List<SemanticsData> items(WidgetTester tester) {
    final found = <SemanticsData>[];
    void visit(SemanticsNode node) {
      final data = node.getSemanticsData();
      if (data.label.isNotEmpty || data.value.isNotEmpty) found.add(data);
      for (final child in node.debugListChildrenInOrder(
        DebugSemanticsDumpOrder.traversalOrder,
      )) {
        visit(child);
      }
    }

    for (final view in tester.binding.renderViews) {
      final root = view.owner?.semanticsOwner?.rootSemanticsNode;
      if (root != null) visit(root);
    }
    return found;
  }

  /// What is wrong at [where], if anything. [header] is the title a screen
  /// reader should hear as a header there.
  Future<void> stop(
    WidgetTester tester,
    List<String> problems,
    String where, {
    String? header,
  }) async {
    final error = tester.takeException();
    if (error != null) problems.add('$where: $error');
    for (final guideline in [
      androidTapTargetGuideline,
      labeledTapTargetGuideline,
    ]) {
      final result = await guideline.evaluate(tester);
      if (!result.passed) problems.add('$where: ${result.reason}');
    }
    final read = items(tester);
    for (final item in read) {
      if (item.flagsCollection.isLiveRegion) {
        problems.add('$where: "${item.label}" is a live region');
      }
    }
    for (var i = 1; i < read.length; i++) {
      final said = read[i].label;
      if (said.isNotEmpty && said == read[i - 1].label) {
        problems.add('$where: "$said" is read twice in a row');
      }
    }
    if (header != null &&
        !read.any(
          (item) => item.flagsCollection.isHeader && item.label == header,
        )) {
      problems.add('$where: "$header" is not a header');
    }
  }

  /// A hatched pet named Pip; in Things, a long task already focused and
  /// planned, one planned for a single block, and one done; and Moving,
  /// with no tasks.
  Future<void> used(TomoDatabase db) async {
    await db.customStatement(
      'UPDATE pets SET name = ?, hatched_at = ?, exp = ?',
      ['Pip', 1, 600 * 12 + 480],
    );
    final tasks = TaskService(db, log: log);
    final things = (await tasks.projects()).first;
    final email = ok(
      await tasks.createTask(
        projectId: things.id,
        title: long,
        notes: 'Chapters 2 and 3. The library copy is on hold.',
        estimate: 4,
      ),
    );
    await db.customStatement(
      'UPDATE tasks SET status = ?, actual_pomodoros = 5, '
      'cumulative_focus_minutes = 125 WHERE id = ?',
      ['doing', email.id],
    );
    ok(
      await tasks.createTask(
        projectId: things.id,
        title: 'Write the intro',
        estimate: 1,
      ),
    );
    final old = ok(
      await tasks.createTask(projectId: things.id, title: 'Read the paper'),
    );
    ok(
      await tasks.updateTask(old.id, const TaskPatch(status: TaskStatus.done)),
    );
    ok(await tasks.createProject('Moving'));
  }

  /// Opens the app at nine, as [pumpTomo] does.
  Future<void> open(
    WidgetTester tester, {
    required ({double dpr, ThemeName theme, double textScale}) look,
    bool onboarded = true,
    Future<void> Function(TomoDatabase db)? before,
  }) async {
    clock = TestClock(nine);
    db = await pumpTomo(
      tester,
      onboarded: onboarded,
      clock: clock.call,
      before: before,
      dpr: look.dpr,
      textScale: look.textScale,
      theme: look.theme,
      // Refused before: the denial line on Ready, and the bell.
      permission: FakePermission(access: (enabled: false, canAsk: false)),
    );
    await settle(tester);
  }

  const looks = <({double dpr, ThemeName theme, double textScale})>[
    (dpr: 2.625, theme: ThemeName.light, textScale: 1),
    (dpr: 2.625, theme: ThemeName.light, textScale: 2),
    (dpr: 2.625, theme: ThemeName.dark, textScale: 2),
    (dpr: 2.8125, theme: ThemeName.dark, textScale: 2),
    (dpr: 3, theme: ThemeName.light, textScale: 2),
  ];

  for (final look in looks) {
    final named =
        '${(look.textScale * 100).round()}% text, ${look.theme.name}, '
        '${look.dpr}×';

    testTomo('onboarding, at $named', (tester) async {
      final semantics = tester.ensureSemantics();
      final problems = <String>[];
      await open(tester, look: look, onboarded: false);

      await stop(
        tester,
        problems,
        'Choose your egg',
        header: 'Choose your egg',
      );
      await tap(tester, button('Next'));
      await stop(
        tester,
        problems,
        'What are you working on?',
        header: 'What are you working on?',
      );

      semantics.dispose();
      expect(problems, isEmpty, reason: problems.join('\n\n'));
    });

    testTomo('the first block and the hatch, at $named', (tester) async {
      final semantics = tester.ensureSemantics();
      final problems = <String>[];
      await open(
        tester,
        look: look,
        before: (db) async {
          await startBlockOn(db);
          clock.now = at(12);
        },
      );

      await stop(
        tester,
        problems,
        'The first block',
        header: 'Write the intro',
      );
      await tap(tester, iconButton('Minimise'));
      await stop(tester, problems, 'Home, the egg cracking');
      await tap(tester, banner());
      await passTo(tester, 25);
      expect(find.words('Name your Geode'), findsOneWidget);
      await stop(tester, problems, 'The hatch, naming');
      await tap(tester, button('Done'));
      await stop(
        tester,
        problems,
        'After the hatch',
        header: 'Write the intro',
      );

      semantics.dispose();
      expect(problems, isEmpty, reason: problems.join('\n\n'));
    });

    testTomo('every other route, sheet and Focus state, at $named', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final problems = <String>[];
      await open(tester, look: look, before: used);

      ProviderScope.containerOf(tester.element(find.byType(HomeScreen)))
          .read(clockNoticeProvider.notifier)
          .show();
      await tester.pump();
      await stop(tester, problems, 'Home, with the clock notice');

      await tap(tester, find.bySemanticsLabel(RegExp('^Level')));
      await stop(tester, problems, 'Stats', header: 'Stats');
      await back(tester);

      await tap(tester, iconButton('Settings'));
      await stop(tester, problems, 'Settings', header: 'Settings');
      await tap(tester, row('Licences'));
      await stop(tester, problems, 'Licences', header: 'Licences');
      await back(tester);
      await back(tester);

      // Ready, then a block running.
      await tap(tester, button('Start focusing'));
      await stop(tester, problems, 'The task picker', header: 'Choose a task');
      await tap(tester, find.bySemanticsLabel(RegExp('^Goes in')));
      await stop(
        tester,
        problems,
        'Choose a project',
        header: 'Choose a project',
      );
      await back(tester);
      await tap(tester, row('Write the intro'));
      await stop(tester, problems, 'Ready', header: 'Write the intro');
      await tap(tester, find.words('Custom · 15 min'));
      await stop(tester, problems, 'The Custom sheet', header: 'Custom length');
      await back(tester);
      await tap(tester, find.words('25 min'));
      await tap(tester, button('Start focusing'));
      await stop(
        tester,
        problems,
        'A block running',
        header: 'Write the intro',
      );
      await tap(tester, button('Stop early'));
      await stop(tester, problems, 'Stop early', header: 'Stop this block?');
      await tap(tester, button('Keep going'));
      await tap(tester, iconButton('Minimise'));
      await stop(tester, problems, 'Home, with the banner');

      // Work while the block runs: the task lock's refusals.
      await tap(tester, tab('Work'));
      await stop(tester, problems, 'Work', header: 'Work');
      await tap(tester, iconButton('New project'));
      await stop(tester, problems, 'New project', header: 'New project');
      await back(tester);
      await tap(tester, row('Things'));
      await stop(tester, problems, 'A project', header: 'Things');
      await tap(tester, iconButton('Project options'));
      await stop(tester, problems, 'The project menu', header: 'Things');
      await back(tester);
      await tap(tester, rowMenu('Read the paper'));
      await stop(tester, problems, 'A row menu', header: 'Read the paper');
      await tap(tester, find.words('Delete task'));
      await stop(tester, problems, 'Delete a task');
      await tap(tester, button('Cancel'));
      await tap(tester, rowMenu('Write the intro'));
      await tap(tester, find.words('Delete task'));
      // The refusal shows under the menu's row; the menu stays.
      expect(saying('Stop it or let it finish first'), findsOneWidget);
      await stop(tester, problems, 'A lock refusal');
      await back(tester);
      await tap(tester, row(long));
      expect(saying('A block is running on'), findsOneWidget);
      await stop(tester, problems, 'Task detail, another block running');
      await tap(tester, tab('Home'));

      // The block ends on Focus: the estimate card, then the task done.
      await tap(tester, banner());
      await passTo(tester, 25);
      expect(find.words('Is this task done?'), findsOneWidget);
      await stop(tester, problems, 'Block done, the estimate card');
      await tap(tester, button('Mark done'));
      expect(button('Start another task'), findsOneWidget);
      await stop(tester, problems, 'Task done');
      await tap(tester, button('Take a 5-min break'));
      await stop(tester, problems, 'The break', header: 'Write the intro');
      await passTo(tester, 30);
      await stop(tester, problems, 'Break over, the task done');
      await tap(tester, button('Done for now'));

      // Under auto-start: the note, the countdown, and the banner after.
      await tap(tester, iconButton('Settings'));
      await tap(tester, find.words('Auto-start'));
      await back(tester);
      await tap(tester, button('Start focusing'));
      await tap(tester, row(long));
      await tap(tester, find.words('25 min'));
      await tap(tester, button('Start focusing'));
      await passTo(tester, 55);
      expect(saying('Break started on its own'), findsOneWidget);
      await stop(tester, problems, 'The break, started on its own');
      await passTo(tester, 60);
      expect(button('Start now'), findsOneWidget);
      await stop(tester, problems, 'The next block counting down');
      await tap(tester, button('Not yet'));
      await stop(tester, problems, 'Break over');
      await tap(tester, button('Start another block'));
      await tap(tester, iconButton('Minimise'));
      await passTo(tester, 85);
      expect(find.byType(FocusScreen), findsNothing);
      expect(banner(), findsOneWidget);
      await stop(tester, problems, 'Home, the block done on the banner');

      semantics.dispose();
      expect(problems, isEmpty, reason: problems.join('\n\n'));
    });
  }
}

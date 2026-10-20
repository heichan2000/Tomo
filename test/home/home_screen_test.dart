import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/focus/live_focus.dart';
import 'package:tomo/app/providers.dart';
import 'package:tomo/focus/task_picker.dart';
import 'package:tomo/home/home_screen.dart';
import 'package:tomo/settings/settings_screen.dart';
import 'package:tomo/stats/stats_screen.dart';
import 'package:tomo/pet/pet_view.dart';
import 'package:tomo/ui/buttons.dart';
import 'package:tomo/ui/exp_bar.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/focus/block_lengths.dart';
import 'package:tomo_core/focus/focus_cycle_service.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/pet/pet_look.dart';
import 'package:tomo_core/result.dart';

import '../app/app_harness.dart';
import '../ui/kit_harness.dart';

/// Home (spec §8.3): the pet with its name and EXP, or the egg and its line
/// before the hatch; the level chip, the gear, the clock notice and *Start
/// focusing*.
void main() {
  Finder iconButton(String label) => find.byWidgetPredicate(
    (widget) => widget is PixelIconButton && widget.semanticLabel == label,
  );

  Finder levelChip() => find.byWidgetPredicate(
    (widget) =>
        widget is Pressable && (widget.semanticLabel ?? '').startsWith('Level'),
  );

  PetView pet(WidgetTester tester) =>
      tester.widget(find.byType(PetView, skipOffstage: false));

  /// Hatches the harness's Geode as [name] with [exp], as the settle and the
  /// naming step would.
  Future<void> hatch(
    WidgetTester tester,
    TomoDatabase db, {
    String? name = 'Pip',
    int exp = 600 * 12 + 480,
  }) async {
    await tester.runAsync(
      () => db.customStatement(
        "UPDATE pets SET name = ${name == null ? 'NULL' : "'$name'"}, "
        'exp = $exp, hatched_at = 1',
      ),
    );
    await petChanged(tester, db);
    await tester.pumpAndSettle();
  }

  /// Starts a 25-minute block on a new task.
  Future<void> startABlock(WidgetTester tester, TomoDatabase db) async {
    await tester.runAsync(() async {
      final project = await db
          .into(db.projects)
          .insert(ProjectsCompanion.insert(name: 'Thesis', createdAt: 0));
      final task = await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              projectId: project,
              title: 'Outline',
              createdAt: 0,
            ),
          );
      final started = await FocusCycleService(db, log: Log(sinks: const []))
          .startBlock(
            taskId: task,
            lengths: BlockLengths.preset25,
            autoStart: false,
          );
      expect(started, isA<Success<Object?>>());
    });
    await petChanged(tester, db);
  }

  testTomo('before the hatch: the egg and its line, no chip, name or bar', (
    tester,
  ) async {
    await pumpTomo(tester);

    expect(pet(tester).look, isA<EggLook>());
    expect(pet(tester).spot, PetSpot.home);
    expect(
      pet(tester).semanticLabel,
      'Stone egg. It hatches when you finish '
      'a focus block.',
    );
    expect(
      find.words('Your stone egg hatches when you finish a focus block.'),
      findsOneWidget,
    );
    expect(levelChip(), findsNothing);
    expect(find.byType(ExpBar), findsNothing);
    expect(iconButton('Settings'), findsOneWidget);
    expect(find.words('Start focusing'), findsOneWidget);
  });

  testTomo('after the hatch: chip, name, the EXP bar and its line', (
    tester,
  ) async {
    final db = await pumpTomo(tester);
    await hatch(tester, db);

    expect(
      pet(tester).look,
      isA<HatchedLook>()
          .having((p) => p.stage, 'stage', 2)
          .having((p) => p.face, 'face', Face.resting),
    );
    expect(
      pet(tester).semanticLabel,
      'Pip, level 13. 480 of 600 EXP toward level 14. Stage 2 of 4.',
    );
    expect(find.words('Lv 13'), findsOneWidget);
    expect(find.words('Pip'), findsOneWidget);
    expect(find.words('480 / 600 EXP'), findsOneWidget);
    expect(tester.widget<ExpBar>(find.byType(ExpBar)).lit, 16);
    expect(
      find.words('Your stone egg hatches when you finish a focus block.'),
      findsNothing,
    );
  });

  testTomo('a pet never named goes by its species', (tester) async {
    final db = await pumpTomo(tester);
    await hatch(tester, db, name: null, exp: 150);

    expect(find.words('Geode'), findsOneWidget);
    expect(find.words('Lv 1'), findsOneWidget);
    expect(find.words('150 / 600 EXP'), findsOneWidget);
    expect(tester.widget<ExpBar>(find.byType(ExpBar)).lit, 5);
  });

  testTomo('Calm pet stills the face', (tester) async {
    final db = await pumpTomo(tester);
    await hatch(tester, db);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );

    await tester.runAsync(
      () => container.read(calmPetProvider.notifier).set(true),
    );
    await tester.pump();

    expect((pet(tester).look as HatchedLook).face, Face.still);
  });

  testTomo('the level chip opens Stats, the gear Settings', (tester) async {
    final db = await pumpTomo(tester);
    await hatch(tester, db);

    await tester.tap(levelChip());
    await tester.pumpAndSettle();
    expect(find.byType(StatsScreen), findsOneWidget);
    await tester.tap(iconButton('Back'));
    await tester.pumpAndSettle();

    await tester.tap(iconButton('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testTomo('Start focusing opens the picker, or Focus while a cycle is live', (
    tester,
  ) async {
    final db = await pumpTomo(tester);

    await tester.tap(find.words('Start focusing'));
    await tester.pumpAndSettle();
    expect(find.byType(TaskPickerSheet), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await startABlock(tester, db);
    await tester.tap(find.words('Start focusing'));
    await tester.pumpAndSettle();
    expect(find.byType(TaskPickerSheet), findsNothing);
    expect(find.byType(LiveFocus), findsOneWidget);
  });

  testTomo('a running block cracks the egg on Home, and it holds still', (
    tester,
  ) async {
    final db = await pumpTomo(tester);
    await startABlock(tester, db);

    final egg = pet(tester).look as EggLook;
    expect(egg.mayWobble, isFalse);
  });

  testTomo('the clock notice shows above the pet until dismissed', (
    tester,
  ) async {
    await pumpTomo(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    const notice =
        "Your phone's clock moved back during a block, so that block "
        "couldn't count. Everything you finished before is safe.";
    expect(find.words(notice), findsNothing);

    container.read(clockNoticeProvider.notifier).show();
    await tester.pump();
    expect(find.words(notice), findsOneWidget);
    expect(
      tester.getRect(find.words(notice)).bottom,
      lessThan(tester.getRect(find.byType(PetView)).top),
    );

    await tester.tap(iconButton('Dismiss'));
    await tester.pump();
    expect(find.words(notice), findsNothing);
  });

  group('the hello', () {
    Future<int> hellosOnComingBack(WidgetTester tester) async {
      var hellos = 0;
      pet(tester).cues!.addListener(() => hellos++);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      return hellos;
    }

    testTomo('plays on coming back to Home', (tester) async {
      final db = await pumpTomo(tester);
      await hatch(tester, db);

      expect(await hellosOnComingBack(tester), 1);
    });

    testTomo('not when coming back to another tab, or to Settings', (
      tester,
    ) async {
      final db = await pumpTomo(tester);
      await hatch(tester, db);

      await tester.tap(iconButton('Settings'));
      await tester.pumpAndSettle();
      expect(await hellosOnComingBack(tester), 0);
    });
  });

  testTomo('nothing overflows at 200% text, in both themes', (tester) async {
    for (final dpr in screens) {
      for (final theme in ThemeName.values) {
        final db = await pumpTomo(tester, dpr: dpr, textScale: 2, theme: theme);
        expect(tester.takeException(), isNull);
        await hatch(tester, db);
        ProviderScope.containerOf(tester.element(find.byType(HomeScreen)))
            .read(clockNoticeProvider.notifier)
            .show();
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.words('Pip'), findsOneWidget);
      }
    }
  });
}

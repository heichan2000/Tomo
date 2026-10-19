import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/notification_watch.dart';
import 'package:tomo/app/providers.dart';
import 'package:tomo/app/routes.dart';
import 'package:tomo/app/timer_buzz.dart';
import 'package:tomo_core/focus/live_cycle.dart';
import 'package:tomo_core/notifications/haptics.dart';
import 'package:tomo_core/pet/pet_standing.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/testing.dart';

/// The timer buzz (spec §11.5): while Tomo is open, a block or a break
/// running out is felt, unless Focus's beat run fires the reward tap
/// instead. Promise 23.
void main() {
  // A 25-minute block from 09:00 UTC with a 5-minute break.
  final start = DateTime.utc(2026, 10, 10, 9);
  DateTime at(int minute) => start.add(Duration(minutes: minute));

  LiveCycle cycle({bool autoStart = false, DateTime? breakStartAt}) =>
      LiveCycle(
        taskId: 1,
        startAt: start,
        endAt: at(25),
        focusMinutes: 25,
        breakMinutes: 5,
        autoStart: autoStart,
        breakStartAt: breakStartAt,
        blockRecordId: breakStartAt == null ? null : 7,
      );

  PetStanding pet(LiveCycle? live) => PetStanding(
    species: Species.geode,
    name: 'Pebble',
    exp: 250,
    hatched: true,
    cycle: live,
  );

  late TestClock clock;
  late _Haptics haptics;
  late StreamController<PetStanding?> changes;
  late FocusRouteObserver focusRoutes;

  /// Opens the buzz on [live] at [minute] past nine.
  Future<void> open(WidgetTester tester, LiveCycle? live, int minute) async {
    clock = TestClock(at(minute));
    haptics = _Haptics();
    changes = StreamController<PetStanding?>.broadcast();
    focusRoutes = FocusRouteObserver();
    final db = openTestDatabase(clock: clock.call);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(db.close);
      await changes.close();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          startingPetProvider.overrideWithValue(pet(live)),
          petChangesProvider.overrideWithValue(changes.stream),
          hapticPlayerProvider.overrideWithValue(haptics),
        ],
        child: TimerBuzz(focusRoutes: focusRoutes, child: const SizedBox()),
      ),
    );
  }

  /// Moves the clock, and the app's timers with it, to [minute] past nine.
  Future<void> passTo(WidgetTester tester, int minute) async {
    final by = at(minute).difference(clock.now);
    clock.now = at(minute);
    await tester.pump(by);
  }

  void openFocus() => focusRoutes.didPush(
    PageRouteBuilder<void>(
      settings: const RouteSettings(name: focusRouteName),
      pageBuilder: (_, _, _) => const SizedBox(),
    ),
    null,
  );

  testWidgets('a block that runs out on another screen buzzes, once', (
    tester,
  ) async {
    await open(tester, cycle(), 10);

    await passTo(tester, 24);
    expect(haptics.played, isEmpty);
    await passTo(tester, 25);
    expect(haptics.played, [Haptic.timerBuzz]);
    await passTo(tester, 60);
    expect(haptics.played, [Haptic.timerBuzz]);
  });

  testWidgets('a block that runs out on Focus is left to its beat run', (
    tester,
  ) async {
    await open(tester, cycle(), 10);
    openFocus();

    await passTo(tester, 25);
    expect(haptics.played, isEmpty);
  });

  testWidgets('a break that runs out on Focus buzzes', (tester) async {
    await open(tester, cycle(breakStartAt: at(26)), 27);
    openFocus();

    await passTo(tester, 31);
    expect(haptics.played, [Haptic.timerBuzz]);
  });

  testWidgets('with auto-start, the block and then its break each buzz', (
    tester,
  ) async {
    await open(tester, cycle(autoStart: true), 10);

    await passTo(tester, 25);
    expect(haptics.played, [Haptic.timerBuzz]);
    await passTo(tester, 30);
    expect(haptics.played, [Haptic.timerBuzz, Haptic.timerBuzz]);
  });

  testWidgets('away from Tomo nothing buzzes: the notification speaks', (
    tester,
  ) async {
    await open(tester, cycle(), 10);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );

    await passTo(tester, 25);
    expect(haptics.played, isEmpty);
  });

  testWidgets('a block stopped early never buzzes', (tester) async {
    await open(tester, cycle(), 10);

    changes.add(pet(null));
    await tester.pump();
    await passTo(tester, 25);
    expect(haptics.played, isEmpty);
  });

  testWidgets('a block started while open buzzes at its end', (tester) async {
    await open(tester, null, 0);

    changes.add(pet(cycle()));
    await tester.pump();
    await passTo(tester, 25);
    expect(haptics.played, [Haptic.timerBuzz]);
  });
}

final class _Haptics implements HapticPlayer {
  final played = <Haptic>[];

  @override
  Future<void> play(Haptic haptic) async => played.add(haptic);
}

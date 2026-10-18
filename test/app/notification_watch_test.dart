import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/focus/live_focus.dart';
import 'package:tomo/app/providers.dart';
import 'package:tomo/app/tomo_app.dart';
import 'package:tomo/platform/notifications.dart';
import 'package:tomo_core/data/instants.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/focus/block_lengths.dart';
import 'package:tomo_core/focus/focus_cycle_service.dart';
import 'package:tomo_core/notifications/notification_schedule.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_service.dart';

import '../platform/fake_notifications.dart';
import 'app_harness.dart';

/// The app keeping the phone's notifications in step (spec §11.1, §11.2,
/// §11.4): synced on every lifecycle change, re-read on resume, and a tap
/// bringing Focus forward.
void main() {
  /// Starts a 25-minute block on a new task, before the app opens.
  Future<void> startBlock(TomoDatabase db) async {
    final project = await db.select(db.projects).getSingle();
    final task = await TaskService(
      db,
      log: Log(sinks: const []),
    ).createTask(projectId: project.id, title: 'Outline');
    await FocusCycleService(db, log: Log(sinks: const [])).startBlock(
      taskId: (task as Success<Task>).value.id,
      lengths: const BlockLengths(focusMinutes: 25, breakMinutes: 5),
      autoStart: false,
    );
  }

  /// Lets the database and the fake phone work on the real clock until
  /// [done], or fails.
  Future<void> until(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(done(), isTrue);
  }

  void goTo(WidgetTester tester, List<AppLifecycleState> states) {
    for (final state in states) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  void leave(WidgetTester tester) => goTo(tester, const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]);

  void comeBack(WidgetTester tester) => goTo(tester, const [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]);

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(TomoApp)));

  testTomo('opening clears what was delivered', (tester) async {
    final phone = FakeScheduler();
    await pumpTomo(tester, notifications: phone);

    await until(tester, () => phone.clearedDelivered > 0);
    expect(phone.pending, isEmpty);
  });

  testTomo('leaving schedules the block\'s end, and coming back clears it', (
    tester,
  ) async {
    final phone = FakeScheduler();
    await pumpTomo(tester, notifications: phone, before: startBlock);
    await until(tester, () => phone.clearedDelivered > 0);

    leave(tester);
    await until(tester, () => phone.pending.isNotEmpty);
    expect(
      phone.pending[NotificationSlot.blockEnd]!.kind,
      NotificationKind.blockComplete,
    );

    final cleared = phone.clearedDelivered;
    comeBack(tester);
    await until(tester, () => phone.pending.isEmpty);
    await until(tester, () => phone.clearedDelivered > cleared);
  });

  testTomo('coming back reads the permission again', (tester) async {
    final permission = FakePermission();
    await pumpTomo(tester, permission: permission);
    final container = containerOf(tester);
    final first = container.read(notificationAccessProvider.future);
    await until(
      tester,
      () => container.read(notificationAccessProvider).hasValue,
    );
    expect(await first, NotificationAccess.notDetermined);

    // Turned on in the phone's settings while Tomo was away.
    leave(tester);
    permission.access = (enabled: true, canAsk: true);
    comeBack(tester);
    await until(
      tester,
      () =>
          container.read(notificationAccessProvider).value ==
          NotificationAccess.granted,
    );
  });

  group('asking', () {
    Future<ProviderContainer> asked(
      WidgetTester tester,
      FakePermission permission,
    ) async {
      await pumpTomo(tester, permission: permission);
      final container = containerOf(tester);
      final done = container.read(notificationAccessProvider.notifier).ask();
      var finished = false;
      unawaited(done.then((_) => finished = true));
      await until(tester, () => finished);
      return container;
    }

    testTomo('a refusal is remembered: denied, never asked again', (
      tester,
    ) async {
      final permission = FakePermission()
        ..answer = (granted: false, answered: true);
      final container = await asked(tester, permission);

      expect(
        container.read(notificationAccessProvider).value,
        NotificationAccess.denied,
      );
    });

    testTomo('a dismissal is not: the next start asks again', (tester) async {
      final permission = FakePermission()
        ..answer = (granted: false, answered: false);
      final container = await asked(tester, permission);

      expect(
        container.read(notificationAccessProvider).value,
        NotificationAccess.notDetermined,
      );
    });

    testTomo('a yes is granted', (tester) async {
      final container = await asked(tester, FakePermission());

      expect(
        container.read(notificationAccessProvider).value,
        NotificationAccess.granted,
      );
    });
  });

  group('a tapped notification', () {
    testTomo('brings Focus forward while its cycle is live', (tester) async {
      final taps = StreamController<String?>();
      addTearDown(taps.close);
      late int startAt;
      final db = await pumpTomo(
        tester,
        notificationTaps: taps.stream,
        before: startBlock,
      );
      await tester.runAsync(() async {
        startAt = (await db.select(db.focusCycle).getSingle()).startAt;
      });
      // Minimised: the cold start opened Focus over the shell.
      Navigator.of(tester.element(find.byType(LiveFocus))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(LiveFocus), findsNothing);

      taps.add('$startAt');
      await until(tester, () => find.byType(LiveFocus).evaluate().isNotEmpty);
      await tester.pumpAndSettle();
      expect(find.byType(LiveFocus), findsOneWidget);

      // Tapped again with Focus already open: still one.
      taps.add('$startAt');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LiveFocus), findsOneWidget);
    });

    testTomo('for a cycle that has gone does nothing', (tester) async {
      final taps = StreamController<String?>();
      addTearDown(taps.close);
      await pumpTomo(tester, notificationTaps: taps.stream);

      taps.add('${epochMs(DateTime.utc(2026))}');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LiveFocus), findsNothing);
    });
  });
}

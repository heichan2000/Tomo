import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/providers.dart';
import 'package:tomo/app/start_up.dart';
import 'package:tomo_core/data/settings.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/diagnostic_entry.dart';
import 'package:tomo_core/diagnostics/diagnostic_log.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/focus/block_lengths.dart';
import 'package:tomo_core/focus/focus_cycle_service.dart';
import 'package:tomo_core/onboarding/onboarding.dart';
import 'package:tomo_core/pet/personality.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/task_service.dart';
import 'package:tomo_core/testing.dart';

import '../platform/fake_notifications.dart';

/// Start-up (spec §6.2, §8.1, C19): what it opens, where a cold start lands,
/// and that a database it can't open stops everything but the error block.
void main() {
  late TestClock clock;
  late RecordingSink sink;
  late Log log;
  late MemoryKeyValueStore keyValues;

  setUp(() {
    clock = TestClock(DateTime.utc(2026, 10, 14, 9));
    sink = RecordingSink();
    log = Log(sinks: [sink]);
    keyValues = MemoryKeyValueStore();
  });

  Future<TomoStart> start(TomoDatabase db) => startTomo(
    database: db,
    keyValues: keyValues,
    deviceFile: MemoryDeviceFileStorage(),
    log: log,
    diagnostics: _diagnostics(),
  );

  Future<TomoDatabase> onboarded() async {
    final db = openTestDatabase(clock: clock.call, log: log);
    addTearDown(db.close);
    await Onboarding(db, log: log).complete(
      species: Species.lily,
      personality: Personality.quiet,
      defaultProjectName: 'Things',
      line: 'Write the intro',
    );
    return db;
  }

  Future<void> startBlock(TomoDatabase db) async {
    final tasks = await TaskService(db, log: log).watchPickerTasks().first;
    final started = await FocusCycleService(db, log: log).startBlock(
      taskId: tasks.single.id,
      lengths: BlockLengths.preset25,
      autoStart: false,
    );
    expect(started, isA<Success<CycleStanding>>());
  }

  /// A container holding what [start] handed out, and the phone's
  /// notifications, which `main()` adds.
  ProviderContainer containerOf(TomoStart started) {
    final container = ProviderContainer(
      overrides: [
        ...(started as Started).overrides,
        notificationSchedulerProvider.overrideWithValue(FakeScheduler()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('a cold start lands', () {
    test('on Onboarding while there is no pet', () async {
      final db = openTestDatabase(clock: clock.call, log: log);
      addTearDown(db.close);

      final started = await start(db);

      expect(started, isA<Started>());
      expect((started as Started).first, FirstSurface.onboarding);
    });

    test('on Home when nothing is running', () async {
      final started = await start(await onboarded());

      expect((started as Started).first, FirstSurface.home);
    });

    test('on Focus while a block runs', () async {
      final db = await onboarded();
      await startBlock(db);
      clock.advance(const Duration(minutes: 10));

      expect((await start(db) as Started).first, FirstSurface.focus);
    });

    test(
      'on Focus, already credited, when a block finished while closed',
      () async {
        final db = await onboarded();
        await startBlock(db);
        clock.advance(const Duration(days: 2));

        expect((await start(db) as Started).first, FirstSurface.focus);
        final records = await db.select(db.blockRecords).get();
        expect(records, hasLength(1));
        expect(records.single.minutes, 25);
      },
    );

    test('on Home with the clock notice when the clock went back', () async {
      final db = await onboarded();
      await startBlock(db);
      clock.advance(const Duration(hours: -1));

      final started = await start(db) as Started;

      expect(started.first, FirstSurface.home);
      expect(containerOf(started).read(clockNoticeProvider), isTrue);
      expect(await db.select(db.blockRecords).get(), isEmpty);
    });
  });

  group('what it hands out', () {
    test('the database, the services and the stores', () async {
      final db = await onboarded();
      final container = containerOf(await start(db));

      expect(container.read(databaseProvider), same(db));
      expect(container.read(logProvider), same(log));
      expect(container.read(focusCycleServiceProvider), isNotNull);
      expect(container.read(taskServiceProvider), isNotNull);
      expect(container.read(statsReaderProvider), isNotNull);
      expect(container.read(beatQueueProvider), isNotNull);
      expect(container.read(onboardingProvider), isNotNull);
      expect(container.read(diagnosticLogProvider), isNotNull);
      expect(
        await container
            .read(deviceOnlyFileProvider)
            .notificationPermissionAsked(),
        isFalse,
      );
      expect(container.read(clockNoticeProvider), isFalse);
    });

    test('the theme Settings asks for, and remembers a change', () async {
      keyValues.values['appearance'] = 'dark';
      final container = containerOf(await start(await onboarded()));

      expect(container.read(appearanceProvider), Appearance.dark);

      await container.read(appearanceProvider.notifier).set(Appearance.light);

      expect(container.read(appearanceProvider), Appearance.light);
      expect(keyValues.values['appearance'], 'light');
    });

    test('no accent before the hatch, then the pet\'s', () async {
      final db = await onboarded();
      await startBlock(db);
      final container = containerOf(await start(db));

      expect(container.read(hatchedSpeciesProvider), isNull);

      // The first block finishes, and the egg hatches.
      clock.advance(const Duration(minutes: 25));
      await container.read(focusCycleServiceProvider).reconcile();
      await pumpEventQueue();

      expect(container.read(hatchedSpeciesProvider), Species.lily);
    });

    test('a hatched pet has its accent from the first frame', () async {
      final db = await onboarded();
      await startBlock(db);
      clock.advance(const Duration(minutes: 25));
      final container = containerOf(await start(db));

      expect(container.read(hatchedSpeciesProvider), Species.lily);
    });

    test('a services provider read without start-up fails loudly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(() => container.read(databaseProvider), throwsA(anything));
    });
  });

  group('a database it cannot open', () {
    test('stops start-up and is recorded', () async {
      keyValues.values['appearance'] = 'dark';
      final db = openNewerTestDatabase(log: log);

      final started = await start(db);

      expect(started, isA<StartFailed>());
      expect((started as StartFailed).appearance, Appearance.dark);
      expect(
        sink.entries.map((e) => e.code),
        contains(DiagnosticCode.storageStartFailed),
      );
    });
  });

  test(
    'a settings store that fails still opens, in the phone\'s theme',
    () async {
      final started = await startTomo(
        database: await onboarded(),
        keyValues: _BrokenStore(),
        deviceFile: MemoryDeviceFileStorage(),
        log: log,
        diagnostics: _diagnostics(),
      );

      expect(containerOf(started).read(appearanceProvider), Appearance.system);
    },
  );
}

final class _BrokenStore implements KeyValueStore {
  @override
  Future<Object?> read(String key) => Future.error(StateError('broken'));

  @override
  Future<void> write(String key, Object value) async {}

  @override
  Future<void> remove(String key) async {}
}

DiagnosticLog _diagnostics() => DiagnosticLog(
  MemoryDiagnosticLogStorage(),
  facts: () async => const DeviceFacts(
    appVersion: '1.0.0',
    buildNumber: '1',
    osVersion: 'android 16',
    deviceClass: DeviceClass.phone,
    locale: 'en-US',
  ),
);

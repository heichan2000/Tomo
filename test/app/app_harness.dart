import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/providers.dart';
import 'package:tomo/app/start_up.dart';
import 'package:tomo/app/tomo_app.dart';
import 'package:tomo/app/tomo_look.dart';
import 'package:tomo/work/work_lists.dart';
import 'package:tomo_core/clock.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/diagnostic_log.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/focus/block_lengths.dart';
import 'package:tomo_core/focus/focus_cycle_service.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/onboarding/onboarding.dart';
import 'package:tomo_core/pet/pet_standing.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_service.dart';
import 'package:tomo_core/testing.dart';

import '../platform/fake_notifications.dart';
import '../ui/kit_harness.dart';

/// Opens the whole app, as `main()` does, on a database in memory: started
/// by [startTomo], so it lands where a cold start would. With [onboarded] the
/// pet already exists.
///
/// [before] runs on the database before start-up, as if Tomo had been used
/// earlier. With [clock] the database tells that time; without, the real
/// time.
///
/// Returns the database, closed again when the test ends.
Future<TomoDatabase> pumpTomo(
  WidgetTester tester, {
  bool onboarded = true,
  double dpr = 2.625,
  Size physicalSize = const Size(1080, 2400),
  double textScale = 1,
  ThemeName theme = ThemeName.light,
  FakeScheduler? notifications,
  FakePermission? permission,
  Stream<String?> notificationTaps = const Stream.empty(),
  Future<void> Function(TomoDatabase db)? before,
  Clock? clock,
}) async {
  await loadArkPixel();
  await _closeAll(tester);
  tester.view
    ..devicePixelRatio = dpr
    ..physicalSize = physicalSize;
  addTearDown(tester.view.reset);
  lookOverride.value = LookOverride(theme: theme, textScale: textScale);
  addTearDown(() => lookOverride.value = const LookOverride());

  final log = Log(sinks: const []);
  final db = openTestDatabase(clock: clock, log: log);
  final started = await tester.runAsync(() async {
    if (onboarded) {
      await Onboarding(
        db,
        log: log,
      ).complete(species: Species.geode, defaultProjectName: 'Things');
    }
    await before?.call(db);
    return startTomo(
      database: db,
      keyValues: MemoryKeyValueStore(),
      deviceFile: MemoryDeviceFileStorage(),
      log: log,
      diagnostics: DiagnosticLog(
        MemoryDiagnosticLogStorage(),
        facts: () async => const DeviceFacts(
          appVersion: '1.0.0',
          buildNumber: '1',
          osVersion: 'android 16',
          deviceClass: DeviceClass.phone,
          locale: 'en-US',
        ),
      ),
    );
  });
  final ready = started! as Started;
  await _feedWork(tester, db);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...ready.overrides,
        notificationSchedulerProvider.overrideWithValue(
          notifications ?? FakeScheduler(),
        ),
        notificationPermissionProvider.overrideWithValue(
          permission ?? FakePermission(),
        ),
        notificationTapsProvider.overrideWithValue(notificationTaps),
        speciesChangesProvider.overrideWithValue(_speciesChanges.stream),
        petChangesProvider.overrideWithValue(_petChanges.stream),
        cycleTaskChangesProvider.overrideWithValue(_cycleTaskChanges.stream),
        workListsProvider.overrideWithValue(_work),
      ],
      child: TomoApp(first: ready.first),
    ),
  );
  await tester.pumpAndSettle();
  _open.add(db);
  return db;
}

final _open = <TomoDatabase>[];

/// For [pumpTomo]'s `before`: a task called [title] in the first project,
/// and a block started on it now. Gives back the task's id.
Future<int> startBlockOn(
  TomoDatabase db, {
  String title = 'Write the intro',
  BlockLengths lengths = BlockLengths.preset25,
  bool autoStart = false,
}) async {
  final log = Log(sinks: const []);
  final tasks = TaskService(db, log: log);
  final project = (await tasks.projects()).first;
  final task = (await tasks.createTask(
    projectId: project.id,
    title: title,
  ) as Success<Task>).value;
  final started = await FocusCycleService(
    db,
    log: log,
  ).startBlock(taskId: task.id, lengths: lengths, autoStart: autoStart);
  expect(started, isA<Success<CycleStanding>>());
  return task.id;
}

var _petChanges = StreamController<PetStanding?>.broadcast();
var _work = _FedWorkLists();
var _speciesChanges = StreamController<Species?>.broadcast();
var _cycleTaskChanges = StreamController<CycleTask?>.broadcast();

/// Tells the app the pet, the cycle or the Work lists changed, as watching
/// the database would: reads [db] on the real clock and hands the pet, its
/// species once hatched (the accent), the cycle's task, and every project
/// with its tasks, to the screens.
Future<void> petChanged(WidgetTester tester, TomoDatabase db) async {
  final (pet, task) = (await tester.runAsync(
    () async => (
      await PetReader(db).read(),
      await TaskService(db, log: Log(sinks: const [])).cycleTask(),
    ),
  ))!;
  _petChanges.add(pet);
  _speciesChanges.add(pet != null && pet.hatched ? pet.species : null);
  _cycleTaskChanges.add(task);
  await _feedWork(tester, db);
  // One frame to deliver it, one to show it.
  await tester.pump();
  await tester.pump();
}

/// A widget test of the whole app. When [body] ends, the app is taken down
/// and its database closed, inside the test.
///
/// The database's work runs on the real clock ([WidgetTester.runAsync]): its
/// watched queries never finish on a widget test's pretend one. So the pet,
/// and the species the accent comes from, change on screen only when a test
/// calls [petChanged].
void testTomo(String description, WidgetTesterCallback body) =>
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        await _closeAll(tester);
      }
    });

/// Takes down the app [pumpTomo] opened and closes its database.
Future<void> _closeAll(WidgetTester tester) async {
  if (_open.isEmpty) return;
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  for (final db in _open) {
    await tester.runAsync(db.close);
  }
  _open.clear();
  await _petChanges.close();
  _petChanges = StreamController<PetStanding?>.broadcast();
  await _speciesChanges.close();
  _speciesChanges = StreamController<Species?>.broadcast();
  await _cycleTaskChanges.close();
  _cycleTaskChanges = StreamController<CycleTask?>.broadcast();
  await _work.close();
  _work = _FedWorkLists();
  await tester.pump();
}

/// Reads the Work lists from [db] on the real clock and hands them to the
/// screens watching them.
Future<void> _feedWork(WidgetTester tester, TomoDatabase db) async {
  final (projects, tasks) = (await tester.runAsync(() async {
    final service = TaskService(db, log: Log(sinks: const []));
    final projects = await service.projectSummaries();
    return (
      projects,
      {
        for (final summary in projects)
          summary.project.id: await service.tasksInProject(summary.project.id),
      },
    );
  }))!;
  _work.feed(projects, tasks);
}

/// The Work lists as [petChanged] last read them. Each new watcher hears
/// the latest at once, as a watched query would.
final class _FedWorkLists implements WorkLists {
  final _changes = StreamController<void>.broadcast();
  var _projects = const <ProjectSummary>[];
  var _tasks = const <int, List<Task>>{};

  void feed(List<ProjectSummary> projects, Map<int, List<Task>> tasks) {
    _projects = projects;
    _tasks = tasks;
    _changes.add(null);
  }

  Future<void> close() => _changes.close();

  Stream<T> _latest<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  @override
  Stream<List<ProjectSummary>> projects() => _latest(() => _projects);

  @override
  Stream<List<Task>> tasksIn(int projectId) =>
      _latest(() => _tasks[projectId] ?? const <Task>[]);

  @override
  Stream<Task?> task(int id) => _latest(
    () => _tasks.values
        .expand((tasks) => tasks)
        .where((t) => t.id == id)
        .firstOrNull,
  );
}

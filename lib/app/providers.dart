import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/data/device_only_file.dart';
import 'package:tomo_core/data/settings.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/diagnostic_log.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/focus/focus_cycle_service.dart';
import 'package:tomo_core/notifications/haptics.dart';
import 'package:tomo_core/notifications/notification_schedule.dart';
import 'package:tomo_core/notifications/notification_sync.dart';
import 'package:tomo_core/onboarding/onboarding.dart';
import 'package:tomo_core/pet/beat_queue.dart';
import 'package:tomo_core/pet/pet_standing.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/stats/stats.dart';
import 'package:tomo_core/tasks/task.dart';
import 'package:tomo_core/tasks/task_service.dart';

import '../platform/haptics.dart';
import '../platform/notifications.dart';

// What every screen reads Tomo through: hand-written Riverpod providers, no
// code generation (spec §15.2).
//
// The first group is set once at start-up by [startTomo]'s overrides; read
// without them, they fail loudly. The rest are built from the first.

Never _setAtStartUp() =>
    throw StateError('Set by startTomo; a test sets it with an override.');

/// The one emit path (spec §13).
final logProvider = Provider<Log>((ref) => _setAtStartUp());

/// The diagnostic log itself, for Settings → About → *Share diagnostics*.
final diagnosticLogProvider = Provider<DiagnosticLog>((ref) => _setAtStartUp());

/// The open database, its start already reported `ready`.
final databaseProvider = Provider<TomoDatabase>((ref) => _setAtStartUp());

/// The six settings (spec §6.3).
final settingsProvider = Provider<Settings>((ref) => _setAtStartUp());

/// The facts that stay on this phone (spec §6.1).
final deviceOnlyFileProvider = Provider<DeviceOnlyFile>(
  (ref) => _setAtStartUp(),
);

/// The phone's notifications (spec §11). Set by `main()`; a test sets a
/// recorder.
final notificationSchedulerProvider = Provider<NotificationScheduler>(
  (ref) => _setAtStartUp(),
);

/// The phone's side of the notification permission (spec §11.4).
final notificationPermissionProvider = Provider<NotificationPermission>(
  (ref) => _setAtStartUp(),
);

/// The phone's haptics (spec §11.5). A test sets a recorder.
final hapticPlayerProvider = Provider<HapticPlayer>(
  (ref) => const SystemHaptics(),
);

/// The payload of each notification tapped while Tomo is running.
final notificationTapsProvider = Provider<Stream<String?>>(
  (ref) => const Stream.empty(),
);

/// Keeps the phone's pending notifications equal to the stored cycle
/// (spec §11.2). Every cycle and task write runs it, and so does every
/// lifecycle change.
final notificationSyncProvider = Provider(
  (ref) => NotificationSync(
    ref.watch(databaseProvider),
    ref.watch(notificationSchedulerProvider),
    log: ref.watch(logProvider),
    isForeground: appIsForeground,
  ),
);

final focusCycleServiceProvider = Provider(
  (ref) => FocusCycleService(
    ref.watch(databaseProvider),
    log: ref.watch(logProvider),
    afterWrite: ref.watch(notificationSyncProvider).sync,
  ),
);

final taskServiceProvider = Provider(
  (ref) => TaskService(
    ref.watch(databaseProvider),
    log: ref.watch(logProvider),
    afterWrite: ref.watch(notificationSyncProvider).sync,
  ),
);

/// Whether Tomo may post notifications (spec §11.4). Read at the first look,
/// and again on every resume, because the phone's settings can change it
/// while Tomo is away.
final notificationAccessProvider =
    AsyncNotifierProvider<NotificationAccessNow, NotificationAccess>(
      NotificationAccessNow.new,
    );

class NotificationAccessNow extends AsyncNotifier<NotificationAccess> {
  @override
  Future<NotificationAccess> build() => _read();

  Future<NotificationAccess> _read() async => notificationAccess(
    await ref.read(notificationPermissionProvider).read(),
    asked: await ref.read(deviceOnlyFileProvider).notificationPermissionAsked(),
  );

  /// Reads the phone again. Called on every resume.
  Future<void> refresh() async => state = await AsyncValue.guard(_read);

  /// Shows the phone's dialog and returns once it has closed, whatever the
  /// answer (spec §11.4): the first block anchors only then. An answer is
  /// remembered on this phone; a dismissal is not, so the next start asks
  /// again.
  Future<void> ask() async {
    final outcome = await ref.read(notificationPermissionProvider).ask();
    if (outcome.answered) {
      await ref.read(deviceOnlyFileProvider).setNotificationPermissionAsked();
    }
    await refresh();
  }

  /// The phone's notification settings for Tomo: the bell, and Settings →
  /// Notifications.
  Future<void> openSettings() =>
      ref.read(notificationPermissionProvider).openSettings();
}

final onboardingProvider = Provider(
  (ref) => Onboarding(ref.watch(databaseProvider), log: ref.watch(logProvider)),
);

final statsReaderProvider = Provider(
  (ref) => StatsReader(ref.watch(databaseProvider)),
);

final beatQueueProvider = Provider(
  (ref) => BeatQueue(ref.watch(databaseProvider)),
);

/// Settings → Appearance, as read at start-up and changed since.
final appearanceProvider = NotifierProvider<AppearanceNotifier, Appearance>(
  AppearanceNotifier.new,
);

final startingAppearanceProvider = Provider<Appearance>(
  (ref) => _setAtStartUp(),
);

class AppearanceNotifier extends Notifier<Appearance> {
  @override
  Appearance build() => ref.read(startingAppearanceProvider);

  /// Changes the theme at once and remembers the choice.
  Future<void> set(Appearance value) {
    state = value;
    return ref.read(settingsProvider).setAppearance(value);
  }
}

/// The pet's species once it has hatched, or null before: the accent comes
/// from it (spec §9.1). Read at start-up, so the first frame has the right
/// colour, then kept up to date from the database.
final hatchedSpeciesProvider = NotifierProvider<HatchedSpecies, Species?>(
  HatchedSpecies.new,
);

final startingSpeciesProvider = Provider<Species?>((ref) => _setAtStartUp());

class HatchedSpecies extends Notifier<Species?> {
  @override
  Species? build() {
    final changes = ref
        .watch(speciesChangesProvider)
        .listen((species) => state = species);
    ref.onDispose(changes.cancel);
    return ref.read(startingSpeciesProvider);
  }
}

/// Where [HatchedSpecies] hears of a change: the database. Widget tests of
/// the whole app replace it, because the database's watched queries can't
/// run on a widget test's pretend clock.
final speciesChangesProvider = Provider<Stream<Species?>>(
  (ref) => watchHatchedSpecies(ref.watch(databaseProvider)),
);

/// The hatched pet's species as it changes; null before the hatch and before
/// onboarding.
Stream<Species?> watchHatchedSpecies(TomoDatabase db) => db
    .select(db.pets)
    .watchSingleOrNull()
    .map((pet) => pet?.hatchedAt == null ? null : pet!.species);

/// Whether Home shows the clock notice (spec §8.3): the clock moved back and
/// a block was discarded. Held in memory until dismissed or the app process
/// ends (§17, C2).
final clockNoticeProvider = NotifierProvider<ClockNotice, bool>(
  ClockNotice.new,
);

final startingClockNoticeProvider = Provider<bool>((ref) => _setAtStartUp());

class ClockNotice extends Notifier<bool> {
  @override
  bool build() => ref.read(startingClockNoticeProvider);

  void show() => state = true;
  void dismiss() => state = false;
}

/// Settings → Calm pet (spec §7.7), as read at start-up and changed since.
final calmPetProvider = NotifierProvider<CalmPet, bool>(CalmPet.new);

final startingCalmPetProvider = Provider<bool>((ref) => _setAtStartUp());

class CalmPet extends Notifier<bool> {
  @override
  bool build() => ref.read(startingCalmPetProvider);

  /// Stills the pet at once and remembers the choice.
  Future<void> set(bool value) {
    state = value;
    return ref.read(settingsProvider).setCalmPet(value);
  }
}

/// The pet as Home shows it (spec §8.3), or null before onboarding. Read at
/// start-up, so the first frame has the pet, then kept up to date from the
/// database.
final petStandingProvider = NotifierProvider<PetStandingNow, PetStanding?>(
  PetStandingNow.new,
);

final startingPetProvider = Provider<PetStanding?>((ref) => _setAtStartUp());

class PetStandingNow extends Notifier<PetStanding?> {
  @override
  PetStanding? build() {
    final changes = ref.watch(petChangesProvider).listen((pet) => state = pet);
    ref.onDispose(changes.cancel);
    return ref.read(startingPetProvider);
  }
}

/// Where [PetStandingNow] hears of a change: the database. Widget tests of
/// the whole app replace it, as with [speciesChangesProvider].
final petChangesProvider = Provider<Stream<PetStanding?>>(
  (ref) => PetReader(ref.watch(databaseProvider)).watch(),
);

/// The task the live cycle is on, and its project (Focus's header, the
/// banner), or null with no cycle. Read at start-up, so a cold start onto
/// Focus has its header, then kept up to date from the database.
final cycleTaskProvider = NotifierProvider<CycleTaskNow, CycleTask?>(
  CycleTaskNow.new,
);

final startingCycleTaskProvider = Provider<CycleTask?>(
  (ref) => _setAtStartUp(),
);

class CycleTaskNow extends Notifier<CycleTask?> {
  @override
  CycleTask? build() {
    final changes = ref
        .watch(cycleTaskChangesProvider)
        .listen((task) => state = task);
    ref.onDispose(changes.cancel);
    return ref.read(startingCycleTaskProvider);
  }
}

/// Where [CycleTaskNow] hears of a change: the database. Widget tests of the
/// whole app replace it, as with [speciesChangesProvider].
final cycleTaskChangesProvider = Provider<Stream<CycleTask?>>(
  (ref) => ref.watch(taskServiceProvider).watchCycleTask(),
);

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tomo_core/data/device_only_file.dart';
import 'package:tomo_core/data/settings.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/diagnostic_log.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/focus/focus_cycle_service.dart';
import 'package:tomo_core/onboarding/onboarding.dart';
import 'package:tomo_core/pet/beat_queue.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/stats/stats.dart';
import 'package:tomo_core/tasks/task_service.dart';

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

final focusCycleServiceProvider = Provider(
  (ref) => FocusCycleService(
    ref.watch(databaseProvider),
    log: ref.watch(logProvider),
  ),
);

final taskServiceProvider = Provider(
  (ref) =>
      TaskService(ref.watch(databaseProvider), log: ref.watch(logProvider)),
);

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

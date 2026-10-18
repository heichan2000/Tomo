import 'package:flutter_riverpod/misc.dart';
import 'package:tomo_core/data/device_only_file.dart';
import 'package:tomo_core/data/settings.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/diagnostic_entry.dart';
import 'package:tomo_core/diagnostics/diagnostic_log.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/focus/focus_cycle_service.dart';
import 'package:tomo_core/focus/projection.dart';
import 'package:tomo_core/onboarding/onboarding.dart';
import 'package:tomo_core/pet/pet_standing.dart';
import 'package:tomo_core/result.dart';
import 'package:tomo_core/tasks/task_service.dart';

import 'providers.dart';

/// Where a cold start lands (spec §8.1).
enum FirstSurface {
  /// No pet yet: setup, above the shell.
  onboarding,

  /// The cycle projects to `idle`.
  home,

  /// The cycle is live: Focus, above the shell, with no hello on Home.
  focus,
}

/// How start-up went.
sealed class TomoStart {
  const TomoStart();
}

/// Everything is open. Hand [overrides] to the `ProviderScope`.
final class Started extends TomoStart {
  const Started({required this.overrides, required this.first});

  final List<Override> overrides;
  final FirstSurface first;
}

/// The database could not be opened (spec §6.2, C19): its file is untouched,
/// a diagnostic entry is written, and the app shows only the error block.
final class StartFailed extends TomoStart {
  const StartFailed({required this.appearance});

  /// The theme to show the error block in. The settings are not in the
  /// database, so they can still be read.
  final Appearance appearance;
}

/// Opens Tomo's stores, brings the focus cycle up to now, and says which
/// surface to open (spec §8.1): Onboarding until the pet exists, then Focus
/// if the cycle is live and Home if it is `idle`.
///
/// A block that finished while Tomo was closed is settled here, exactly once
/// (§4.4), so Focus opens on it already credited.
Future<TomoStart> startTomo({
  required TomoDatabase database,
  required KeyValueStore keyValues,
  required DeviceFileStorage deviceFile,
  required Log log,
  required DiagnosticLog diagnostics,
}) async {
  final settings = Settings(keyValues);
  final appearance = await _orDefault(
    settings.appearance(),
    Appearance.system,
    log,
  );
  final calmPet = await _orDefault(settings.calmPet(), false, log);

  if (await database.start() == StorageStart.failed) {
    return StartFailed(appearance: appearance);
  }

  try {
    final onboarded = await Onboarding(database, log: log).isComplete();
    var first = FirstSurface.onboarding;
    var clockNotice = false;
    if (onboarded) {
      final standing = switch (await FocusCycleService(
        database,
        log: log,
      ).reconcile()) {
        Success(:final value) => value,
        // Already recorded by the service.
        Failure() => null,
      };
      if (standing == null) {
        await database.close();
        return StartFailed(appearance: appearance);
      }
      first = standing.state == FocusState.idle
          ? FirstSurface.home
          : FirstSurface.focus;
      clockNotice = standing.clockNotice;
    }
    final species = await watchHatchedSpecies(database).first;
    final pet = await PetReader(database).read();
    final cycleTask = await TaskService(database, log: log).cycleTask();

    return Started(
      first: first,
      overrides: [
        logProvider.overrideWithValue(log),
        diagnosticLogProvider.overrideWithValue(diagnostics),
        databaseProvider.overrideWithValue(database),
        settingsProvider.overrideWithValue(settings),
        deviceOnlyFileProvider.overrideWithValue(DeviceOnlyFile(deviceFile)),
        startingAppearanceProvider.overrideWithValue(appearance),
        startingSpeciesProvider.overrideWithValue(species),
        startingClockNoticeProvider.overrideWithValue(clockNotice),
        startingCalmPetProvider.overrideWithValue(calmPet),
        startingPetProvider.overrideWithValue(pet),
        startingCycleTaskProvider.overrideWithValue(cycleTask),
      ],
    );
  } catch (error, stackTrace) {
    log.error(DiagnosticCode.storageStartFailed, error, stackTrace);
    await database.close();
    return StartFailed(appearance: appearance);
  }
}

/// A setting that can't be read falls back to its default (spec §6.3); a
/// broken settings file never stops Tomo opening.
Future<T> _orDefault<T>(Future<T> read, T fallback, Log log) async {
  try {
    return await read;
  } catch (error, stackTrace) {
    log.error(DiagnosticCode.unanticipated, error, stackTrace);
    return fallback;
  }
}

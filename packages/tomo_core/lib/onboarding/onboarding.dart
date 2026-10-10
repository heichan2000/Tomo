import 'package:drift/drift.dart';

import '../data/instants.dart';
import '../data/tomo_database.dart';
import '../diagnostics/diagnostic_entry.dart';
import '../diagnostics/log.dart';
import '../pet/personality.dart';
import '../pet/species.dart';
import '../result.dart';
import '../tasks/task_service.dart';

/// What finishing onboarding writes (spec §8.2).
///
/// Nothing is written until the second screen is finished or skipped. Then
/// one transaction creates the pet (an unnamed egg), the first project, and
/// the first task if a line was typed. Cut off before that, onboarding starts
/// again from its first screen.
final class Onboarding {
  Onboarding(this._db, {required this._log});

  final TomoDatabase _db;
  final Log _log;

  /// Whether onboarding has been finished: the pet exists.
  Future<bool> isComplete() async =>
      await _db.select(_db.pets).getSingleOrNull() != null;

  /// Finishes onboarding.
  ///
  /// [line] is what the user typed for "What are you working on?". It becomes
  /// both the project's name and the first task. Null or blank means the
  /// screen was skipped: the project is named [defaultProjectName] and there
  /// is no task.
  ///
  /// Finishing a second time writes nothing.
  Future<Result<void>> complete({
    required Species species,
    required Personality personality,
    required String defaultProjectName,
    String? line,
  }) async {
    final typed = line?.trim() ?? '';
    final skipped = typed.isEmpty;
    final String name;
    switch (checkProjectName(skipped ? defaultProjectName : typed)) {
      case Success(:final value):
        name = value;
      case Failure(:final error):
        return Failure(error);
    }

    try {
      await _db.transaction(() async {
        if (await isComplete()) return;
        final now = epochMs(_db.clock().toUtc());
        await _db
            .into(_db.pets)
            .insert(
              PetsCompanion.insert(
                species: species,
                personality: Value(personality),
                createdAt: now,
              ),
            );
        final projectId = await _db
            .into(_db.projects)
            .insert(ProjectsCompanion.insert(name: name, createdAt: now));
        if (!skipped) {
          await _db
              .into(_db.tasks)
              .insert(
                TasksCompanion.insert(
                  projectId: projectId,
                  title: name,
                  createdAt: now,
                ),
              );
        }
      });
      return const Success(null);
    } catch (error, stackTrace) {
      _log.error(DiagnosticCode.onboardingWriteFailed, error, stackTrace);
      return const Failure(StorageFailed());
    }
  }
}

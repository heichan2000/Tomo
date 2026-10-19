import 'dart:async';

import 'package:characters/characters.dart';
import 'package:drift/drift.dart';

import '../data/tomo_database.dart';
import '../diagnostics/diagnostic_entry.dart';
import '../diagnostics/log.dart';
import '../result.dart';

/// The longest name a pet can have, in characters as a reader counts them:
/// about what fits on one line at the pet-name size (spec §17).
const maxPetNameLength = 20;

/// The pet's own writes: its name, given at the hatch's *Done* (spec §8.7)
/// and changed later in Settings. Species is permanent and has no writer;
/// EXP moves only through the settle and the bonus.
final class PetService {
  PetService(this._db, {required this._log, this._afterWrite});

  final TomoDatabase _db;
  final Log _log;

  /// Run after every write that commits: the notifications are titled with
  /// the pet's name (spec §11.1).
  final Future<void> Function()? _afterWrite;

  /// Names the pet [name], trimmed. Blank, or longer than
  /// [maxPetNameLength], is refused and the old name stays.
  ///
  /// There is no pet before onboarding, and no screen can name one then.
  Future<Result<String>> rename(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Failure(Invalid(InvalidField.petName, InvalidRule.empty));
    }
    if (trimmed.characters.length > maxPetNameLength) {
      return const Failure(
        Invalid(
          InvalidField.petName,
          InvalidRule.tooLong,
          limit: maxPetNameLength,
        ),
      );
    }
    try {
      await _db.update(_db.pets).write(PetsCompanion(name: Value(trimmed)));
    } catch (error, stackTrace) {
      _log.error(DiagnosticCode.petWriteFailed, error, stackTrace);
      return const Failure(StorageFailed());
    }
    unawaited(_afterWrite?.call());
    return Success(trimmed);
  }
}

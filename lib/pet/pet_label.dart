import 'package:tomo_core/pet/pet_look.dart';
import 'package:tomo_core/pet/pet_standing.dart';
import 'package:tomo_core/rewards/rewards.dart';

import '../l10n/app_localizations.dart';

/// What a screen reader says for [pet] shown as [look] (spec §10.4): its
/// name, level, EXP and stage, or before the hatch, its egg, named so as not
/// to give the pet away (ADR-0031).
String petLabel(AppLocalizations words, PetStanding pet, PetLook look) {
  final speciesName = words.speciesName(pet.species.name);
  return switch (look) {
    HatchedLook(:final stage) => words.srPet(
      pet.name ?? speciesName,
      pet.level,
      pet.exp % expPerLevel,
      pet.level + 1,
      stage,
    ),
    EggLook() => words.srEgg(words.eggName(pet.species.name)),
  };
}

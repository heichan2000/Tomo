/// The reward numbers (spec §3, ADR-0001, ADR-0007).
///
/// EXP is the only reward number Tomo has. Every grant is linear in finished
/// focus minutes. Level and stage are worked out from EXP here and stored
/// nowhere.
library;

/// EXP per completed focus minute.
const expPerFocusMinute = 10;

/// EXP per level: one hour of focus. The curve is flat forever.
const expPerLevel = 600;

/// The level each of the four evolution stages begins at.
const stageStartLevels = [1, 10, 40, 100];

/// The largest EXP total: a 32-bit signed integer. A technical bound, not a
/// designed cap.
const maxExp = 0x7fffffff;

/// What a finished focus block of [minutes] earns.
int expForBlock({required int minutes}) => minutes * expPerFocusMinute;

/// The level a pet with [exp] is at. A new pet is level 1.
int levelForExp(int exp) => exp ~/ expPerLevel + 1;

/// The evolution stage, 1 to 4, a pet at [level] is in.
int stageForLevel(int level) =>
    stageStartLevels.where((start) => level >= start).length;

/// The evolution stage, 1 to 4, a pet with [exp] is in.
int stageForExp(int exp) => stageForLevel(levelForExp(exp));

/// The one-time bonus for finishing a task: 10% of what its own blocks
/// earned, which is one EXP per focus minute.
int completionBonus({required int cumulativeFocusMinutes}) =>
    cumulativeFocusMinutes;

/// [exp] plus [grant], held at [maxExp].
int addExp(int exp, int grant) {
  final total = exp + grant;
  return total > maxExp ? maxExp : total;
}

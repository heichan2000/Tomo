import 'package:tomo_core/notifications/notification_schedule.dart';
import 'package:tomo_core/pet/beat.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/voice/number_words.dart';
import 'package:tomo_core/voice/pet_moment.dart';

import '../l10n/app_localizations.dart';

/// The pet's line for [moment] (spec §10).
///
/// Each pet has one line per moment, in its own character (ADR-0030). Some
/// moments also have a line that adds a fact, said only when that fact is
/// true (`factHolds`); otherwise the pet says the usual line.
///
/// The words are all in the copy file. Geode's numbers are spelled out here,
/// because Geode never uses digits.
String petLine(
  AppLocalizations l, {
  required PetMoment moment,
  required Species species,
}) {
  final s = species.name;
  const words = numberWords;
  const startWords = numberWordsCapitalized;

  switch (moment) {
    case BlockDoneMoment(
      :final factHolds,
      :final minutes,
      :final task,
      :final taskBlocks,
      :final taskMinutes,
    ):
      return factHolds
          ? l.blockDoneTaskTotal(
              s,
              minutes,
              startWords(minutes),
              startWords(taskMinutes),
              task,
              taskBlocks,
            )
          : l.blockDone(s, minutes, startWords(minutes));
    case LevelUpMoment(
      :final factHolds,
      :final level,
      :final levelBefore,
      :final hours,
      :final totalMinutes,
    ):
      return factHolds
          ? l.levelUpTotalTime(
              s,
              level,
              words(level),
              levelBefore,
              hours,
              startWords(hours),
              totalMinutes,
            )
          : l.levelUp(s, level, words(level), levelBefore);
    case EvolutionMoment(:final stage, :final hours, :final factHolds):
      return factHolds
          ? l.evolutionTotalTime(s, stage, hours, startWords(hours))
          : l.evolution(s, stage);
    case TaskDoneMoment(
      :final task,
      :final taskBlocks,
      :final taskMinutes,
      :final factHolds,
    ):
      return factHolds
          ? l.taskDoneTaskTotal(
              s,
              task,
              taskBlocks,
              taskMinutes,
              startWords(taskMinutes),
            )
          : l.taskDone(s, task);
    case OnBreakMoment(
      :final factHolds,
      :final breakMinutes,
      :final todayBlocks,
      :final todayMinutes,
    ):
      return factHolds
          ? l.onBreakToday(
              s,
              breakMinutes,
              todayBlocks,
              startWords(todayMinutes),
            )
          : l.onBreak(s, breakMinutes);
    case BreakOverMoment(
      :final factHolds,
      :final breakMinutes,
      :final todayBlocks,
      :final todayMinutes,
    ):
      return factHolds
          ? l.breakOverToday(
              s,
              breakMinutes,
              todayBlocks,
              startWords(todayMinutes),
            )
          : l.breakOver(s, breakMinutes);
    case HatchMoment(:final minutes, :final task):
      return l.hatch(s, minutes, startWords(minutes), task);
    case AwayNoteMoment(:final time, :final minutes):
      return l.awayNote(s, time, minutes, startWords(minutes));
    case CountdownMoment(:final seconds):
      return l.countdown(s, seconds, words(seconds));
    case EstimateMoment(:final estimate):
      return l.estimate(s, estimate);
  }
}

/// A timer notification's title and body (spec §11.1).
///
/// The title is the pet's name, or the egg's ("Your stone egg") before the
/// hatch. A pet that hatched but was never named goes by its species. Before
/// the hatch the bodies are plain and name only the egg, so the pet stays a
/// surprise (ADR-0031).
({String title, String body}) notificationText(
  AppLocalizations l,
  TimerNotification notification,
) {
  final content = notification.content;
  final s = content.species.name;
  final minutes = content.focusMinutes;
  final title = content.beforeHatch
      ? l.notifTitleEgg(l.eggInLine(s))
      : content.petName ?? l.speciesName(s);
  final body = switch (notification.kind) {
    NotificationKind.breakComplete when content.beforeHatch =>
      l.notifBreakOverEgg,
    NotificationKind.breakComplete => l.notifBreakOver(s, content.breakMinutes),
    // The first block's notification hints at the hatch, whatever comes next.
    _ when content.beforeHatch => l.notifFirstBlock(
      minutes,
      content.taskTitle,
      l.eggInLine(s),
    ),
    NotificationKind.blockComplete => l.notifBlockDone(
      s,
      content.taskTitle,
      minutes,
      numberWordsCapitalized(minutes),
    ),
    NotificationKind.blockCompleteBreakBegun => l.notifBlockDoneBreakBegun(
      s,
      content.taskTitle,
      minutes,
      numberWordsCapitalized(minutes),
      content.breakMinutes,
    ),
  };
  return (title: title, body: body);
}

/// A length of focus time, written as Stats writes it (spec §8.9): "15 min"
/// under an hour, then "2 h" or "26 h 40 min".
String focusTime(AppLocalizations l, int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return l.focusTimeMinutes(minutes);
  if (rest == 0) return l.focusTimeHours(hours);
  return l.focusTimeHoursMinutes(hours, rest);
}

/// The delete-task sheet's body: what goes, and that focus time stays.
/// Under an hour it counts minutes, as the script does; from an hour up it
/// writes the time as Stats does (#85).
String deleteTaskBody(
  AppLocalizations l, {
  required String task,
  required int minutes,
}) {
  if (minutes == 0) return l.delTaskNone(task);
  if (minutes < 60) return l.delTask(task, minutes);
  return l.delTaskLong(task, focusTime(l, minutes));
}

/// The delete-project sheet's body. [tasks] counts every task in the project,
/// done ones too; [minutes] is the focus time on them.
String deleteProjectBody(
  AppLocalizations l, {
  required int tasks,
  required int minutes,
}) {
  if (tasks == 0) return l.delProjNone;
  if (minutes == 0) return l.delProjNoFocus(tasks);
  return l.delProj(tasks, focusTime(l, minutes));
}

/// What a screen reader speaks once, at the start of a run (spec §10.4):
/// plain facts first, then the pet's name and the line it shows.
///
/// [opening] replaces the first sentence when the block finished while the
/// user was away: pass the *while you were away* note.
String runAnnouncement(
  AppLocalizations l, {
  required RunFacts facts,
  required String petName,
  required String petLine,
  String? opening,
}) {
  final minutes = facts.blockMinutes;
  final level = facts.levelReached;
  final stage = facts.stageReached;
  final exp = facts.expGained;
  return [
    if (facts.hatched)
      l.srRunHatch
    else ...[
      opening ??
          (minutes != null
              ? l.srRunBlock(minutes, facts.taskTitle)
              : l.srRunTask(facts.taskTitle)),
      if (level != null && stage != null)
        l.srRunGainedLevelStage(petName, exp, level, stage)
      else if (level != null)
        l.srRunGainedLevel(petName, exp, level)
      else
        l.srRunGained(petName, exp),
    ],
    l.srRunPetLine(petName, petLine),
  ].join(' ');
}

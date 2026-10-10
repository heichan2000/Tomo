import 'package:tomo_core/notifications/notification_schedule.dart';
import 'package:tomo_core/pet/beat.dart';
import 'package:tomo_core/pet/personality.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/voice/number_words.dart';
import 'package:tomo_core/voice/pet_moment.dart';

import '../l10n/app_localizations.dart';

/// The pet's line for [moment] (spec §10).
///
/// A Quiet pet says the script's line. A Chatty pet says the Chatty entry,
/// which adds one detail, when there is one **and its detail is true**;
/// otherwise it says the Quiet line too.
///
/// The words are all in the copy file. Geode's numbers are spelled out here,
/// because Geode never uses digits.
String petLine(
  AppLocalizations l, {
  required PetMoment moment,
  required Species species,
  required Personality personality,
}) {
  final s = species.name;
  final chatty =
      personality == Personality.chatty && moment.chattyDetailHolds(species);
  const words = numberWords;
  const startWords = numberWordsCapitalized;

  switch (moment) {
    case BlockDoneMoment(
      :final minutes,
      :final task,
      :final taskBlocks,
      :final taskMinutes,
    ):
      return chatty
          ? l.blockDoneChattyTaskTotal(
              s,
              minutes,
              startWords(minutes),
              startWords(taskMinutes),
              task,
              taskBlocks,
            )
          : l.blockDone(s, minutes, startWords(minutes));
    case LevelUpMoment(
      :final level,
      :final levelBefore,
      :final hours,
      :final totalMinutes,
    ):
      return chatty
          ? l.levelUpChattyTotalTime(
              s,
              level,
              words(level),
              levelBefore,
              hours,
              startWords(hours),
              totalMinutes,
            )
          : l.levelUp(s, level, words(level), levelBefore);
    case EvolutionMoment(:final stage, :final hours):
      return chatty
          ? l.evolutionChattyTotalTime(s, stage, hours, startWords(hours))
          : l.evolution(s, stage);
    case TaskDoneMoment(:final task, :final taskBlocks, :final taskMinutes):
      return chatty
          ? l.taskDoneChattyTaskTotal(
              s,
              task,
              taskBlocks,
              taskMinutes,
              startWords(taskMinutes),
            )
          : l.taskDone(s, task);
    case OnBreakMoment(
      :final breakMinutes,
      :final todayBlocks,
      :final todayMinutes,
    ):
      return chatty
          ? l.onBreakChattyToday(
              s,
              breakMinutes,
              todayBlocks,
              startWords(todayMinutes),
            )
          : l.onBreak(s, breakMinutes);
    case BreakOverMoment(
      :final breakMinutes,
      :final todayBlocks,
      :final todayMinutes,
    ):
      return chatty
          ? l.breakOverChattyToday(
              s,
              breakMinutes,
              todayBlocks,
              startWords(todayMinutes),
            )
          : l.breakOver(s, breakMinutes);
    case HatchMoment(:final minutes, :final task):
      return chatty
          ? l.hatchChattyFirstBlock(s, minutes, startWords(minutes), task)
          : l.hatch(s, minutes, startWords(minutes));
    case SetupMoment():
      return chatty ? l.setupChatty(s) : l.setup(s);
    case EggMoment():
      return l.egg(s);
    case AwayNoteMoment(:final time, :final minutes):
      return l.awayNote(s, time, minutes, startWords(minutes));
    case CountdownMoment(:final seconds):
      return l.countdown(s, seconds, words(seconds));
    case EstimateMoment(:final estimate):
      return l.estimate(s, estimate);
  }
}

/// A timer notification's title and body (spec §11.1). Quiet only.
///
/// The title is the pet's name, or "Your egg" before the hatch. A pet that
/// hatched but was never named goes by its species.
({String title, String body}) notificationText(
  AppLocalizations l,
  TimerNotification notification,
) {
  final content = notification.content;
  final s = content.species.name;
  final minutes = content.focusMinutes;
  final title = content.beforeHatch
      ? l.notifTitleEgg
      : content.petName ?? l.speciesName(s);
  final body = switch (notification.kind) {
    NotificationKind.breakComplete => l.notifBreakOver(s, content.breakMinutes),
    // The first block's notification hints at the hatch, whatever comes next.
    _ when content.beforeHatch => l.notifFirstBlock(
      s,
      content.taskTitle,
      minutes,
      numberWordsCapitalized(minutes),
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

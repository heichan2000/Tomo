// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Tomo';

  @override
  String speciesName(String species) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': 'Geode',
      'joe': 'Joe',
      'lily': 'Lily',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String blockDone(String species, int minutes, String minutesWords) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': '$minutesWords minutes. They stay.',
      'joe': '$minutes of $minutes minutes. Counted!',
      'lily': 'You stayed with it the whole way, didn\'t you?',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String blockDoneChattyTaskTotal(
    String species,
    int minutes,
    String minutesWords,
    String taskMinutesWords,
    String task,
    int taskBlocks,
  ) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode':
          '$minutesWords minutes. $taskMinutesWords on $task now, all of it in me.',
      'joe':
          '$minutes of $minutes minutes. Counted! Block $taskBlocks on $task.',
      'lily':
          'You stayed with it the whole way, didn\'t you? That\'s $taskBlocks blocks you\'ve given $task.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String levelUp(
    String species,
    int level,
    String levelWords,
    int levelBefore,
  ) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': 'Level $levelWords. Another hour in me.',
      'joe': 'Level $level! Up from $levelBefore.',
      'lily': 'Level $level. You did that, you know?',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String levelUpChattyTotalTime(
    String species,
    int level,
    String levelWords,
    int levelBefore,
    int hours,
    String hoursWords,
    int totalMinutes,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'hours',
      one: 'hour',
    );
    String _temp1 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'hours',
      one: 'hour',
    );
    String _temp2 = intl.Intl.selectLogic(species, {
      'geode':
          'Level $levelWords. $hoursWords $_temp0 in me now, layer on layer.',
      'joe':
          'Level $level! Up from $levelBefore. $totalMinutes minutes of focus, all counted.',
      'lily':
          'Level $level. That\'s $hours $_temp1 you\'ve focused. Can you believe it?',
      'other': '',
    });
    return '$_temp2';
  }

  @override
  String evolution(String species, int stage) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': 'I am bigger. All of me is still here.',
      'joe': 'Stage $stage of 4!',
      'lily': 'Look at me! You did this, didn\'t you?',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String evolutionChattyTotalTime(
    String species,
    int stage,
    int hours,
    String hoursWords,
  ) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode':
          'I am bigger. $hoursWords hours, and this is what they make. All of me is still here.',
      'joe': 'Stage $stage of 4! Folded from $hours hours of focus.',
      'lily': 'Look at me! $hours hours of your focus did this, didn\'t they?',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String taskDone(String species, String task) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': '$task is done. It stays done.',
      'joe': 'Done: $task!',
      'lily': 'You finished $task. Feels good, doesn\'t it?',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String taskDoneChattyTaskTotal(
    String species,
    String task,
    int taskBlocks,
    int taskMinutes,
    String taskMinutesWords,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      taskBlocks,
      locale: localeName,
      other: 'blocks',
      one: 'block',
    );
    String _temp1 = intl.Intl.selectLogic(species, {
      'geode':
          '$task is done. $taskMinutesWords minutes are in it, and they stay.',
      'joe': 'Done: $task! $taskBlocks $_temp0, $taskMinutes minutes.',
      'lily':
          'You finished $task, all $taskBlocks blocks of it. Feels good, doesn\'t it?',
      'other': '',
    });
    return '$_temp1';
  }

  @override
  String onBreak(String species, int breakMinutes) {
    String _temp0 = intl.Intl.pluralLogic(
      breakMinutes,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    String _temp1 = intl.Intl.selectLogic(species, {
      'geode': 'A break. Everything is still here.',
      'joe': 'Break: $breakMinutes $_temp0.',
      'lily': 'You\'re resting. Nice, isn\'t it?',
      'other': '',
    });
    return '$_temp1';
  }

  @override
  String onBreakChattyToday(
    String species,
    int breakMinutes,
    int todayBlocks,
    String todayMinutesWords,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      breakMinutes,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    String _temp1 = intl.Intl.pluralLogic(
      todayBlocks,
      locale: localeName,
      other: 'blocks',
      one: 'block',
    );
    String _temp2 = intl.Intl.pluralLogic(
      todayBlocks,
      locale: localeName,
      other: 'blocks',
      one: 'block',
    );
    String _temp3 = intl.Intl.selectLogic(species, {
      'geode':
          'A break. $todayMinutesWords minutes today, and everything is still here.',
      'joe': 'Break: $breakMinutes $_temp0. $todayBlocks $_temp1 done today.',
      'lily':
          'You\'re resting after $todayBlocks $_temp2 today. Nice, isn\'t it?',
      'other': '',
    });
    return '$_temp3';
  }

  @override
  String breakOver(String species, int breakMinutes) {
    String _temp0 = intl.Intl.pluralLogic(
      breakMinutes,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    String _temp1 = intl.Intl.selectLogic(species, {
      'geode': 'The break is whole. I am here.',
      'joe': 'Break done: $breakMinutes of $breakMinutes $_temp0.',
      'lily': 'You\'re back. A bit rested now, aren\'t you?',
      'other': '',
    });
    return '$_temp1';
  }

  @override
  String breakOverChattyToday(
    String species,
    int breakMinutes,
    int todayBlocks,
    String todayMinutesWords,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      breakMinutes,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    String _temp1 = intl.Intl.pluralLogic(
      todayBlocks,
      locale: localeName,
      other: 'blocks',
      one: 'block',
    );
    String _temp2 = intl.Intl.pluralLogic(
      todayBlocks,
      locale: localeName,
      other: 'blocks',
      one: 'block',
    );
    String _temp3 = intl.Intl.selectLogic(species, {
      'geode':
          'The break is whole. $todayMinutesWords minutes today, and I am here.',
      'joe':
          'Break done: $breakMinutes of $breakMinutes $_temp0. $todayBlocks $_temp1 so far today.',
      'lily':
          'You\'re back, with $todayBlocks $_temp2 behind you today. A bit rested now, aren\'t you?',
      'other': '',
    });
    return '$_temp3';
  }

  @override
  String hatch(String species, int minutes, String minutesWords) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': '$minutesWords minutes. I am made of them.',
      'joe': 'Hello! 1 block, $minutes minutes, 1 me.',
      'lily': 'Oh! It was you, wasn\'t it?',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String hatchChattyFirstBlock(
    String species,
    int minutes,
    String minutesWords,
    String task,
  ) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': '$minutesWords minutes of $task. I am made of them.',
      'joe':
          'Hello! 1 block, $minutes minutes on $task, 1 me. First of everything!',
      'lily':
          'Oh! It was you, wasn\'t it? $minutes minutes on $task, and here I am.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String setup(String species) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': 'I am Geode. I keep every minute.',
      'joe': 'Joe. 1 paper bird. I count.',
      'lily': 'I\'m Lily. I\'d like to know you.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String setupChatty(String species) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': 'I am Geode. I keep every minute of focus, layer on layer, and I like to say so.',
      'joe': 'I\'m Joe! 1 paper bird who counts every block and every minute, out loud.',
      'lily': 'I\'m Lily! I notice every block you finish, and I tell you about it. You don\'t mind, do you?',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String egg(String species) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': 'I am in here. A finished focus block opens me.',
      'joe': '1 egg. 1 focus block to hatch.',
      'lily': 'I hatch when you finish a focus block. Shall we?',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String awayNote(
    String species,
    String time,
    int minutes,
    String minutesWords,
  ) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode':
          '$time: the block is whole, with no one watching. $minutesWords minutes, counted.',
      'joe': 'Finished at $time. $minutes of $minutes minutes, counted.',
      'lily':
          'Your block finished at $time while you were away. All $minutes minutes count.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String countdown(String species, int seconds, String secondsWords) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': 'The next block begins in $secondsWords.',
      'joe': 'Next block in $seconds.',
      'lily': 'Your next block starts in $seconds. Ready?',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String estimate(String species, int estimate) {
    String _temp0 = intl.Intl.pluralLogic(
      estimate,
      locale: localeName,
      other: 'blocks',
      one: 'block',
    );
    String _temp1 = intl.Intl.pluralLogic(
      estimate,
      locale: localeName,
      other: 'blocks',
      one: 'block',
    );
    String _temp2 = intl.Intl.selectLogic(species, {
      'geode': 'Every planned block is here.',
      'joe': '$estimate of $estimate planned $_temp0.',
      'lily': 'That\'s all $estimate $_temp1 you planned for it.',
      'other': '',
    });
    return '$_temp2';
  }

  @override
  String get notifTitleEgg => 'Your egg';

  @override
  String notifBlockDone(
    String species,
    String task,
    int minutes,
    String minutesWords,
  ) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': '$minutesWords minutes of $task. They are counted.',
      'joe': '$task: $minutes of $minutes minutes, counted.',
      'lily': 'You gave $task $minutes minutes. Every one of them counted.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String notifBlockDoneBreakBegun(
    String species,
    String task,
    int minutes,
    String minutesWords,
    int breakMinutes,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      breakMinutes,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    String _temp1 = intl.Intl.selectLogic(species, {
      'geode': '$minutesWords minutes of $task, counted. The break is here.',
      'joe':
          '$task: $minutes of $minutes minutes, counted. Break started: $breakMinutes $_temp0.',
      'lily':
          'You gave $task $minutes minutes, and they all counted. Your break has begun.',
      'other': '',
    });
    return '$_temp1';
  }

  @override
  String notifBreakOver(String species, int breakMinutes) {
    String _temp0 = intl.Intl.pluralLogic(
      breakMinutes,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    String _temp1 = intl.Intl.selectLogic(species, {
      'geode': 'The break is whole. I am here.',
      'joe': 'Break finished: $breakMinutes of $breakMinutes $_temp0.',
      'lily': 'Your break is over. Did you stretch? Either way, it was yours.',
      'other': '',
    });
    return '$_temp1';
  }

  @override
  String notifFirstBlock(
    String species,
    String task,
    int minutes,
    String minutesWords,
  ) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': '$minutesWords minutes of $task, counted. My shell is cracking.',
      'joe':
          '$task: $minutes of $minutes minutes, counted. My shell: 5 cracks.',
      'lily':
          'You gave $task $minutes minutes, and my shell is cracking. Who\'s in here, I wonder?',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get notifHiddenBlock => 'A focus block counted.';

  @override
  String get notifHiddenBreak => 'A break finished.';

  @override
  String get notifPreviewsOff => 'Something you started has finished.';

  @override
  String get pickTitle => 'Choose your pet';

  @override
  String get pickLine =>
      'You keep this one. It hatches from an egg when you finish your first focus block.';

  @override
  String get persLabel => 'Personality';

  @override
  String get persHint =>
      'How much your pet says. You can change it in Settings.';

  @override
  String get taskTitle => 'What are you working on?';

  @override
  String get taskLine => 'One line is enough. It becomes your first task.';

  @override
  String get permFrame =>
      'When a block ends, Tomo can tell you, even with the app closed. Your phone will ask first.';

  @override
  String get permDenied =>
      'Notifications are off, so Tomo can\'t tell you when a block ends. Your blocks still count. The bell at the top opens your phone\'s settings.';

  @override
  String get autoNote =>
      'Break started on its own. Auto-start is on (change it in Settings).';

  @override
  String get clock =>
      'Your phone\'s clock moved back during a block, so that block couldn\'t count. Everything you finished before is safe.';

  @override
  String get stopTitle => 'Stop this block?';

  @override
  String get stopBody =>
      'Only finished blocks count, so this one won\'t. Everything you\'ve finished before stays.';

  @override
  String get delTaskTitle => 'Delete this task?';

  @override
  String delTask(String task, int minutes) {
    return '\"$task\" and its notes go for good. The $minutes minutes you focused on it stay in your stats.';
  }

  @override
  String delTaskNone(String task) {
    return '\"$task\" and its notes go for good. It has no focus time, so your stats don\'t change.';
  }

  @override
  String delProjTitle(String project) {
    return 'Delete \"$project\"?';
  }

  @override
  String delProj(int count, String duration) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Its $count tasks go with it, for good.',
      one: 'Its 1 task goes with it, for good.',
    );
    return '$_temp0 The $duration you focused on them stays in your stats.';
  }

  @override
  String get delProjNone => 'It has no tasks, so nothing else changes.';

  @override
  String get lockTask =>
      'A block is running on this task. Stop it or let it finish first.';

  @override
  String get lockProject =>
      'A block is running on a task in this project. Stop it or let it finish first.';

  @override
  String get emptyProjectsTitle => 'No projects yet';

  @override
  String get emptyProjects =>
      'A project holds the tasks for one piece of work, like a thesis or a move.';

  @override
  String emptyProjectTitle(String project) {
    return 'Nothing in $project yet';
  }

  @override
  String get emptyProject =>
      'Add the first task. You can focus on it from here or from Home.';

  @override
  String allDone(String project) {
    return 'Everything in $project is done.';
  }

  @override
  String get doneTask => 'To focus on this again, set it back to To do.';

  @override
  String otherRunning(String task) {
    return 'A block is running on \"$task\". Stop it or let it finish first.';
  }

  @override
  String get about =>
      'Tomo never connects to the internet. Your pet and tasks are kept in your phone\'s own backup. Moving between iPhone and Android doesn\'t bring them across.';

  @override
  String get aboutOs =>
      'Your phone may send crash reports to Apple or Google if its settings allow it. Tomo never sees them.';

  @override
  String get shareDiag =>
      'A list of errors, with no tasks, names or notes in it. You choose where it goes.';

  @override
  String get error =>
      'Something went wrong here. If it keeps happening, Settings > About > Share diagnostics makes a report you can send.';

  @override
  String get customTitle => 'Custom length';

  @override
  String get customFocus => 'Focus';

  @override
  String get customBreak => 'Break';

  @override
  String get customUse => 'Use these';

  @override
  String customChip(int minutes) {
    return 'Custom · $minutes min';
  }

  @override
  String get startAnotherTask => 'Start another task';

  @override
  String srPet(String name, int level, int exp, int nextLevel, int stage) {
    return '$name, level $level. $exp of 600 EXP toward level $nextLevel. Stage $stage of 4.';
  }

  @override
  String srEgg(String speciesName) {
    return '$speciesName egg. It hatches when you finish a focus block.';
  }

  @override
  String srClock(int minutes, String task) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    return 'About $minutes $_temp0 left on $task.';
  }

  @override
  String srRunBlock(int minutes, String task) {
    return 'Block done: $minutes minutes on $task.';
  }

  @override
  String srRunTask(String task) {
    return 'Task done: $task.';
  }

  @override
  String get srRunHatch => 'Your egg hatched.';

  @override
  String srRunGained(String name, int exp) {
    return '$name gained $exp EXP.';
  }

  @override
  String srRunGainedLevel(String name, int exp, int level) {
    return '$name gained $exp EXP and reached level $level.';
  }

  @override
  String srRunGainedLevelStage(String name, int exp, int level, int stage) {
    return '$name gained $exp EXP, reached level $level and grew to stage $stage of 4.';
  }

  @override
  String srRunPetLine(String name, String line) {
    return '$name: $line';
  }
}

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
      'geode': '$minutesWords minutes. Nice and steady.',
      'joe': '$minutes of $minutes minutes. Folded, creased, filed.',
      'lily':
          'You did the whole block! You\'re getting good at this, aren\'t you?',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String blockDoneTaskTotal(
    String species,
    int minutes,
    String minutesWords,
    String taskMinutesWords,
    String task,
    int taskBlocks,
  ) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode':
          '$minutesWords minutes. Nice and steady. $taskMinutesWords on $task now.',
      'joe':
          '$minutes of $minutes minutes. Block $taskBlocks on $task, filed in order.',
      'lily':
          'That\'s $taskBlocks blocks for $task now! You don\'t give up, do you?',
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
      'geode': 'Level $levelWords. One more layer, calm and solid.',
      'joe': 'Level $level! Up from $levelBefore. Records updated, neatly.',
      'lily': 'Level $level! I knew you could do it, didn\'t I?',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String levelUpTotalTime(
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
          'Level $levelWords. $hoursWords $_temp0 of layers now, each one holding.',
      'joe':
          'Level $level! Up from $levelBefore. $totalMinutes minutes on file, each in its place.',
      'lily':
          'Level $level! That\'s $hours $_temp1 of focus. You\'re amazing, aren\'t you?',
      'other': '',
    });
    return '$_temp2';
  }

  @override
  String evolution(String species, int stage) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': 'I am bigger. Slowly, gently. All of me is still here.',
      'joe': 'Stage $stage of 4! Refolded. Every crease exactly right.',
      'lily': 'Look at me, I\'m bigger! You did this, didn\'t you?',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String evolutionTotalTime(
    String species,
    int stage,
    int hours,
    String hoursWords,
  ) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode':
          'I am bigger. $hoursWords hours, laid down gently. All of me is still here.',
      'joe':
          'Stage $stage of 4! Refolded from $hours hours of focus. Every crease exactly right.',
      'lily':
          'Look at me! $hours hours of your focus made me bigger. You did this, didn\'t you?',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String taskDone(String species, String task) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': '$task is done. A good, quiet feeling. It stays done.',
      'joe': 'Done: $task! Ticked, filed, put away.',
      'lily': 'You finished $task! That feels great, doesn\'t it?',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String taskDoneTaskTotal(
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
    String _temp1 = intl.Intl.pluralLogic(
      taskBlocks,
      locale: localeName,
      other:
          'You finished $task, all $taskBlocks blocks of it! That feels great, doesn\'t it?',
      one:
          'You finished $task in just one block! That feels great, doesn\'t it?',
    );
    String _temp2 = intl.Intl.selectLogic(species, {
      'geode':
          '$task is done. $taskMinutesWords minutes rest in it, and they stay.',
      'joe':
          'Done: $task! $taskBlocks $_temp0, $taskMinutes minutes. Ticked, filed, put away.',
      'lily': '$_temp1',
      'other': '',
    });
    return '$_temp2';
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
      'geode': 'It\'s break time.',
      'joe': 'Break: $breakMinutes $_temp0. Desk tidied for the next one.',
      'lily': 'Break time! You earned it, didn\'t you?',
      'other': '',
    });
    return '$_temp1';
  }

  @override
  String onBreakToday(
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
      'geode': 'It\'s break time. $todayMinutesWords minutes today.',
      'joe': 'Break: $breakMinutes $_temp0. $todayBlocks $_temp1 filed today.',
      'lily':
          'Break time, after $todayBlocks $_temp2 today! You earned it, didn\'t you?',
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
      'geode': 'The break is whole. Calm, and ready. I am here.',
      'joe':
          'Break done: $breakMinutes of $breakMinutes $_temp0. Desk is tidy and ready.',
      'lily': 'You\'re back! All rested, aren\'t you?',
      'other': '',
    });
    return '$_temp1';
  }

  @override
  String breakOverToday(
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
          'Break done: $breakMinutes of $breakMinutes $_temp0. $todayBlocks $_temp1 on today\'s list.',
      'lily':
          'You\'re back, with $todayBlocks $_temp2 done today! All rested, aren\'t you?',
      'other': '',
    });
    return '$_temp3';
  }

  @override
  String hatch(String species, int minutes, String minutesWords, String task) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': 'Hello. $minutesWords minutes of $task, and I am made of them.',
      'joe':
          'Hello! 1 block, $minutes minutes on $task, 1 me. First entry, filed!',
      'lily':
          'Oh! You did it! $minutes minutes on $task, and here I am. That was you, wasn\'t it?',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String eggName(String species) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': 'Stone egg',
      'joe': 'Paper egg',
      'lily': 'Spotted egg',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String eggInLine(String species) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': 'stone egg',
      'joe': 'paper egg',
      'lily': 'spotted egg',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String eggHint(String species) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': 'Cool, heavy and very still. Something patient is inside.',
      'joe':
          'It rustles, neatly folded at every edge. Something tidy is inside.',
      'lily': 'It wiggles when you look at it. Something cheerful is inside.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String egg(String egg) {
    return 'Your $egg hatches when you finish a focus block.';
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
          '$time: the block is whole, quietly, on its own. $minutesWords minutes, counted.',
      'joe':
          'Finished at $time. $minutes of $minutes minutes, logged and filed.',
      'lily':
          'Your block finished at $time while you were away. All $minutes minutes count, don\'t they?',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String countdown(String species, int seconds, String secondsWords) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': 'Steady. The next block begins in $secondsWords.',
      'joe': 'Next block in $seconds. Pencils sharpened.',
      'lily':
          'Your next block starts in $seconds. You\'ve got this, haven\'t you?',
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
      other:
          'That\'s all $estimate blocks you planned for it. You kept your word, didn\'t you?',
      one: 'That\'s the one block you planned for it. You kept your word, didn\'t you?',
    );
    String _temp2 = intl.Intl.selectLogic(species, {
      'geode': 'Every planned block is here. Steady work, all of it.',
      'joe': '$estimate of $estimate planned $_temp0. Exactly to plan. Lovely.',
      'lily': '$_temp1',
      'other': '',
    });
    return '$_temp2';
  }

  @override
  String notifTitleEgg(String egg) {
    return 'Your $egg';
  }

  @override
  String notifBlockDone(
    String species,
    String task,
    int minutes,
    String minutesWords,
  ) {
    String _temp0 = intl.Intl.selectLogic(species, {
      'geode': '$minutesWords minutes of $task. They settle in, and they stay.',
      'joe': '$task: $minutes of $minutes minutes, filed.',
      'lily': 'You gave $task $minutes minutes! Every one counted, didn\'t it?',
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
      'geode':
          '$minutesWords minutes of $task, counted. The break is here. Breathe.',
      'joe':
          '$task: $minutes of $minutes minutes, filed. Break started: $breakMinutes $_temp0.',
      'lily':
          'You gave $task $minutes minutes! Your break has begun. You earned it, didn\'t you?',
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
      'geode': 'The break is whole. I am here, steady as ever.',
      'joe':
          'Break finished: $breakMinutes of $breakMinutes $_temp0. Desk is ready.',
      'lily': 'Your break is over! Feeling fresh, aren\'t you?',
      'other': '',
    });
    return '$_temp1';
  }

  @override
  String notifFirstBlock(int minutes, String task, String egg) {
    return '$minutes minutes of $task, counted. Your $egg is cracking!';
  }

  @override
  String get notifBreakOverEgg => 'Your break is over.';

  @override
  String get channelFocusBlock => 'Focus block finished';

  @override
  String get channelFocusBlockAbout =>
      'When a focus block you started reaches its end.';

  @override
  String get channelBreak => 'Break finished';

  @override
  String get channelBreakAbout => 'When a break reaches its end.';

  @override
  String get notifHiddenBlock => 'A focus block counted.';

  @override
  String get notifHiddenBreak => 'A break finished.';

  @override
  String get notifPreviewsOff => 'Something you started has finished.';

  @override
  String get pickTitle => 'Choose your egg';

  @override
  String get pickLine =>
      'Whatever is inside is yours to keep. It hatches when you finish your first focus block.';

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
  String delTaskLong(String task, String duration) {
    return '\"$task\" and its notes go for good. The $duration you focused on it stays in your stats.';
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
      other:
          'Its $count tasks go with it, for good. The $duration you focused on them stays in your stats.',
      one:
          'Its 1 task goes with it, for good. The $duration you focused on it stays in your stats.',
    );
    return '$_temp0';
  }

  @override
  String delProjNoFocus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Its $count tasks go with it, for good. They have no focus time, so your stats don\'t change.',
      one: 'Its 1 task goes with it, for good. It has no focus time, so your stats don\'t change.',
    );
    return '$_temp0';
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
  String focusTimeMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString min';
  }

  @override
  String focusTimeHours(int hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    return '$hoursString h';
  }

  @override
  String focusTimeHoursMinutes(int hours, int minutes) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    return '$hoursString h $minutes min';
  }

  @override
  String get startAnotherTask => 'Start another task';

  @override
  String srPet(String name, int level, int exp, int nextLevel, int stage) {
    return '$name, level $level. $exp of 600 EXP toward level $nextLevel. Stage $stage of 4.';
  }

  @override
  String srEgg(String eggName) {
    return '$eggName. It hatches when you finish a focus block.';
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

  @override
  String get tabHome => 'Home';

  @override
  String get tabWork => 'Work';

  @override
  String get back => 'Back';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingDone => 'Done';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get defaultProject => 'My work';

  @override
  String get startFocusing => 'Start focusing';

  @override
  String levelChip(int level) {
    return 'Lv $level';
  }

  @override
  String srLevelChip(int level) {
    return 'Level $level. Stats';
  }

  @override
  String expLine(int exp) {
    return '$exp / 600 EXP';
  }

  @override
  String get settings => 'Settings';

  @override
  String get dismiss => 'Dismiss';

  @override
  String beatGain(int exp) {
    return '+$exp EXP';
  }

  @override
  String beatLevelPlate(int level) {
    return 'Level $level';
  }

  @override
  String get beatTaskPlate => 'Task done';

  @override
  String get focusLeave => 'Leave';

  @override
  String get bellOff => 'Notifications are off';

  @override
  String get readyTask => 'Task';

  @override
  String get readyLength => 'Length';

  @override
  String lengthMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get lengthCustom => 'Custom';

  @override
  String get stepFewer => 'Fewer';

  @override
  String get stepMore => 'More';

  @override
  String get pickerTitle => 'Choose a task';

  @override
  String get newTask => 'New task';

  @override
  String srNewTaskProject(String project) {
    return 'Goes in $project. Change project';
  }

  @override
  String get chooseProject => 'Choose a project';

  @override
  String get statusDoing => 'Doing';

  @override
  String get minimise => 'Minimise';

  @override
  String clockLeft(int minutes) {
    return 'about $minutes min left';
  }

  @override
  String get clockUnderMinute => 'under a minute left';

  @override
  String restLeft(int minutes) {
    return 'about $minutes min of rest left';
  }

  @override
  String get restUnderMinute => 'under a minute of rest left';

  @override
  String get chipFocus => 'Focus';

  @override
  String get chipBreak => 'Break';

  @override
  String get stopEarly => 'Stop early';

  @override
  String get keepGoing => 'Keep going';

  @override
  String get skipBreak => 'Skip break';

  @override
  String get startNow => 'Start now';

  @override
  String get notYet => 'Not yet';

  @override
  String bannerLeft(int minutes) {
    return '$minutes min left';
  }

  @override
  String bannerBreak(int minutes) {
    return 'Break · about $minutes min';
  }

  @override
  String get bannerBreakUnderMinute => 'Break · under a minute';

  @override
  String bannerBlockDone(int minutes) {
    return 'Block done · $minutes min counted';
  }

  @override
  String get bannerBreakOver => 'Break over';

  @override
  String srClockUnderMinute(String task) {
    return 'Under a minute left on $task.';
  }

  @override
  String srRest(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    return 'About $minutes $_temp0 of rest left.';
  }

  @override
  String get srRestUnderMinute => 'Under a minute of rest left.';

  @override
  String choiceBreak(int minutes) {
    return 'Take a $minutes-min break';
  }

  @override
  String choiceAnotherBlock(int minutes) {
    return 'Another $minutes-min block';
  }

  @override
  String get startAnotherBlock => 'Start another block';

  @override
  String get markTaskDone => 'Mark task done';

  @override
  String get doneForNow => 'Done for now';

  @override
  String get estimateTitle => 'Is this task done?';

  @override
  String get estimateMarkDone => 'Mark done';

  @override
  String hatchName(String speciesName) {
    return 'Name your $speciesName';
  }

  @override
  String get hatchDone => 'Done';

  @override
  String get workTitle => 'Work';

  @override
  String get newProject => 'New project';

  @override
  String get createProject => 'Create project';

  @override
  String get projectName => 'Project name';

  @override
  String projectCounts(int open, int done) {
    return '$open open · $done done';
  }

  @override
  String projectAllDone(int count) {
    return 'All $count done';
  }

  @override
  String get projectNoTasks => 'No tasks';

  @override
  String get projectOptions => 'Project options';

  @override
  String get renameProject => 'Rename project';

  @override
  String get renameSave => 'Rename';

  @override
  String get deleteProject => 'Delete project';

  @override
  String get addTask => 'Add a task';

  @override
  String taskBlocksOfPlan(int done, int planned) {
    String _temp0 = intl.Intl.pluralLogic(
      planned,
      locale: localeName,
      other: '$done of $planned blocks',
      one: '$done of 1 block',
    );
    return '$_temp0';
  }

  @override
  String taskBlocksOverPlan(int done, int planned) {
    return '$done blocks · planned $planned';
  }

  @override
  String taskBlocks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count blocks',
      one: '1 block',
    );
    return '$_temp0';
  }

  @override
  String get taskOptions => 'Task options';

  @override
  String srRingMarkDone(String status) {
    return '$status. Mark done';
  }

  @override
  String get srRingReopen => 'Done. Reopen';

  @override
  String get statusTodo => 'To do';

  @override
  String get statusDone => 'Done';

  @override
  String get moveToAnotherProject => 'Move to another project';

  @override
  String get moveToProject => 'Move to project';

  @override
  String get deleteTask => 'Delete task';

  @override
  String get cancel => 'Cancel';
}

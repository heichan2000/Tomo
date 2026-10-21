import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The app's name, as the phone's app switcher shows it.
  ///
  /// In en, this message translates to:
  /// **'Tomo'**
  String get appName;

  /// A species' name.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{Geode} joe{Joe} lily{Lily} other{}}'**
  String speciesName(String species);

  /// Pet voice. A focus block was credited.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{{minutesWords} minutes. Nice and steady.} joe{{minutes} of {minutes} minutes. Folded, creased, filed.} lily{You did the whole block! You\'re getting good at this, aren\'t you?} other{}}'**
  String blockDone(String species, int minutes, String minutesWords);

  /// Pet voice. Block done, with its fact: said when this task has 2 or more blocks.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{{minutesWords} minutes. Nice and steady. {taskMinutesWords} on {task} now.} joe{{minutes} of {minutes} minutes. Block {taskBlocks} on {task}, filed in order.} lily{That\'s {taskBlocks} blocks for {task} now! You don\'t give up, do you?} other{}}'**
  String blockDoneTaskTotal(
    String species,
    int minutes,
    String minutesWords,
    String taskMinutesWords,
    String task,
    int taskBlocks,
  );

  /// Pet voice. The pet reached a level.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{Level {levelWords}. One more layer, calm and solid.} joe{Level {level}! Up from {levelBefore}. Records updated, neatly.} lily{Level {level}! I knew you could do it, didn\'t I?} other{}}'**
  String levelUp(String species, int level, String levelWords, int levelBefore);

  /// Pet voice. Level-up, with its fact: the total time focused, said from the first whole hour.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{Level {levelWords}. {hoursWords} {hours, plural, =1{hour} other{hours}} of layers now, each one holding.} joe{Level {level}! Up from {levelBefore}. {totalMinutes} minutes on file, each in its place.} lily{Level {level}! That\'s {hours} {hours, plural, =1{hour} other{hours}} of focus. You\'re amazing, aren\'t you?} other{}}'**
  String levelUpTotalTime(
    String species,
    int level,
    String levelWords,
    int levelBefore,
    int hours,
    String hoursWords,
    int totalMinutes,
  );

  /// Pet voice. The pet changed stage.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{I am bigger. Slowly, gently. All of me is still here.} joe{Stage {stage} of 4! Refolded. Every crease exactly right.} lily{Look at me, I\'m bigger! You did this, didn\'t you?} other{}}'**
  String evolution(String species, int stage);

  /// Pet voice. Evolution, with its fact: the total time focused.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{I am bigger. {hoursWords} hours, laid down gently. All of me is still here.} joe{Stage {stage} of 4! Refolded from {hours} hours of focus. Every crease exactly right.} lily{Look at me! {hours} hours of your focus made me bigger. You did this, didn\'t you?} other{}}'**
  String evolutionTotalTime(
    String species,
    int stage,
    int hours,
    String hoursWords,
  );

  /// Pet voice. A task was marked done.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{{task} is done. A good, quiet feeling. It stays done.} joe{Done: {task}! Ticked, filed, put away.} lily{You finished {task}! That feels great, doesn\'t it?} other{}}'**
  String taskDone(String species, String task);

  /// Pet voice. Task done, with its fact: said when the task has focus time.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{{task} is done. {taskMinutesWords} minutes rest in it, and they stay.} joe{Done: {task}! {taskBlocks} {taskBlocks, plural, =1{block} other{blocks}}, {taskMinutes} minutes. Ticked, filed, put away.} lily{{taskBlocks, plural, =1{You finished {task} in just one block! That feels great, doesn\'t it?} other{You finished {task}, all {taskBlocks} blocks of it! That feels great, doesn\'t it?}}} other{}}'**
  String taskDoneTaskTotal(
    String species,
    String task,
    int taskBlocks,
    int taskMinutes,
    String taskMinutesWords,
  );

  /// Pet voice. A break is running. (The script calls this key "break", a word Dart keeps for itself.)
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{It\'s break time.} joe{Break: {breakMinutes} {breakMinutes, plural, =1{minute} other{minutes}}. Desk tidied for the next one.} lily{Break time! You earned it, didn\'t you?} other{}}'**
  String onBreak(String species, int breakMinutes);

  /// Pet voice. On a break, with its fact: what was finished today, said when a block ended today.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{It\'s break time. {todayMinutesWords} minutes today.} joe{Break: {breakMinutes} {breakMinutes, plural, =1{minute} other{minutes}}. {todayBlocks} {todayBlocks, plural, =1{block} other{blocks}} filed today.} lily{Break time, after {todayBlocks} {todayBlocks, plural, =1{block} other{blocks}} today! You earned it, didn\'t you?} other{}}'**
  String onBreakToday(
    String species,
    int breakMinutes,
    int todayBlocks,
    String todayMinutesWords,
  );

  /// Pet voice. The break has ended.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{The break is whole. Calm, and ready. I am here.} joe{Break done: {breakMinutes} of {breakMinutes} {breakMinutes, plural, =1{minute} other{minutes}}. Desk is tidy and ready.} lily{You\'re back! All rested, aren\'t you?} other{}}'**
  String breakOver(String species, int breakMinutes);

  /// Pet voice. Break over, with its fact: what was finished today, said when a block ended today.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{The break is whole. {todayMinutesWords} minutes today, and I am here.} joe{Break done: {breakMinutes} of {breakMinutes} {breakMinutes, plural, =1{minute} other{minutes}}. {todayBlocks} {todayBlocks, plural, =1{block} other{blocks}} on today\'s list.} lily{You\'re back, with {todayBlocks} {todayBlocks, plural, =1{block} other{blocks}} done today! All rested, aren\'t you?} other{}}'**
  String breakOverToday(
    String species,
    int breakMinutes,
    int todayBlocks,
    String todayMinutesWords,
  );

  /// Pet voice. The hatch line, after the first finished block, naming its task.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{Hello. {minutesWords} minutes of {task}, and I am made of them.} joe{Hello! 1 block, {minutes} minutes on {task}, 1 me. First entry, filed!} lily{Oh! You did it! {minutes} minutes on {task}, and here I am. That was you, wasn\'t it?} other{}}'**
  String hatch(String species, int minutes, String minutesWords, String task);

  /// Plain voice. An egg's name, under it on onboarding's first screen. It never names the species: the pet is a surprise until the hatch (#114, ADR-0031).
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{Stone egg} joe{Paper egg} lily{Spotted egg} other{}}'**
  String eggName(String species);

  /// Plain voice. An egg's name inside a line ("Your stone egg …").
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{stone egg} joe{paper egg} lily{spotted egg} other{}}'**
  String eggInLine(String species);

  /// Plain voice. The chosen egg's hint, under the tiles on onboarding's first screen (#114).
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{Cool, heavy and very still. Something patient is inside.} joe{It rustles, neatly folded at every edge. Something tidy is inside.} lily{It wiggles when you look at it. Something cheerful is inside.} other{}}'**
  String eggHint(String species);

  /// Plain voice. The egg's line on Home, naming only the egg (#114).
  ///
  /// In en, this message translates to:
  /// **'Your {egg} hatches when you finish a focus block.'**
  String egg(String egg);

  /// Pet voice. A block finished while the user was away. {time} is a time of day as this phone writes it.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{{time}: the block is whole, quietly, on its own. {minutesWords} minutes, counted.} joe{Finished at {time}. {minutes} of {minutes} minutes, logged and filed.} lily{Your block finished at {time} while you were away. All {minutes} minutes count, don\'t they?} other{}}'**
  String awayNote(
    String species,
    String time,
    int minutes,
    String minutesWords,
  );

  /// Pet voice. The auto-start countdown, in seconds.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{Steady. The next block begins in {secondsWords}.} joe{Next block in {seconds}. Pencils sharpened.} lily{Your next block starts in {seconds}. You\'ve got this, haven\'t you?} other{}}'**
  String countdown(String species, int seconds, String secondsWords);

  /// Pet voice. The estimate card's fact line.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{Every planned block is here. Steady work, all of it.} joe{{estimate} of {estimate} planned {estimate, plural, =1{block} other{blocks}}. Exactly to plan. Lovely.} lily{{estimate, plural, =1{That\'s the one block you planned for it. You kept your word, didn\'t you?} other{That\'s all {estimate} blocks you planned for it. You kept your word, didn\'t you?}}} other{}}'**
  String estimate(String species, int estimate);

  /// A notification's title before the hatch, naming only the egg (#114).
  ///
  /// In en, this message translates to:
  /// **'Your {egg}'**
  String notifTitleEgg(String egg);

  /// Notification body. A focus block ended.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{{minutesWords} minutes of {task}. They settle in, and they stay.} joe{{task}: {minutes} of {minutes} minutes, filed.} lily{You gave {task} {minutes} minutes! Every one counted, didn\'t it?} other{}}'**
  String notifBlockDone(
    String species,
    String task,
    int minutes,
    String minutesWords,
  );

  /// Notification body. A focus block ended and auto-start began the break.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{{minutesWords} minutes of {task}, counted. The break is here. Breathe.} joe{{task}: {minutes} of {minutes} minutes, filed. Break started: {breakMinutes} {breakMinutes, plural, =1{minute} other{minutes}}.} lily{You gave {task} {minutes} minutes! Your break has begun. You earned it, didn\'t you?} other{}}'**
  String notifBlockDoneBreakBegun(
    String species,
    String task,
    int minutes,
    String minutesWords,
    int breakMinutes,
  );

  /// Notification body. A break ended.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{The break is whole. I am here, steady as ever.} joe{Break finished: {breakMinutes} of {breakMinutes} {breakMinutes, plural, =1{minute} other{minutes}}. Desk is ready.} lily{Your break is over! Feeling fresh, aren\'t you?} other{}}'**
  String notifBreakOver(String species, int breakMinutes);

  /// Notification body, plain voice. The first block ended, before the hatch (#114).
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes of {task}, counted. Your {egg} is cracking!'**
  String notifFirstBlock(int minutes, String task, String egg);

  /// Notification body, plain voice. A break ended before the hatch was seen (#114).
  ///
  /// In en, this message translates to:
  /// **'Your break is over.'**
  String get notifBreakOverEgg;

  /// Android notification channel name (spec §11.3), shown in the phone's settings.
  ///
  /// In en, this message translates to:
  /// **'Focus block finished'**
  String get channelFocusBlock;

  /// Android notification channel description (spec §11.3).
  ///
  /// In en, this message translates to:
  /// **'When a focus block you started reaches its end.'**
  String get channelFocusBlockAbout;

  /// Android notification channel name (spec §11.3), shown in the phone's settings.
  ///
  /// In en, this message translates to:
  /// **'Break finished'**
  String get channelBreak;

  /// Android notification channel description (spec §11.3).
  ///
  /// In en, this message translates to:
  /// **'When a break reaches its end.'**
  String get channelBreakAbout;

  /// Notification body on Android when content is hidden: a block.
  ///
  /// In en, this message translates to:
  /// **'A focus block counted.'**
  String get notifHiddenBlock;

  /// Notification body on Android when content is hidden: a break.
  ///
  /// In en, this message translates to:
  /// **'A break finished.'**
  String get notifHiddenBreak;

  /// Notification body on iOS when previews are off.
  ///
  /// In en, this message translates to:
  /// **'Something you started has finished.'**
  String get notifPreviewsOff;

  /// Plain voice. Onboarding 1, title (#114).
  ///
  /// In en, this message translates to:
  /// **'Choose your egg'**
  String get pickTitle;

  /// Plain voice. Onboarding 1, line (#114).
  ///
  /// In en, this message translates to:
  /// **'Whatever is inside is yours to keep. It hatches when you finish your first focus block.'**
  String get pickLine;

  /// Plain voice. Onboarding 2, title.
  ///
  /// In en, this message translates to:
  /// **'What are you working on?'**
  String get taskTitle;

  /// Plain voice. Onboarding 2, line.
  ///
  /// In en, this message translates to:
  /// **'One line is enough. It becomes your first task.'**
  String get taskLine;

  /// Plain voice. Focus, before the phone asks about notifications.
  ///
  /// In en, this message translates to:
  /// **'When a block ends, Tomo can tell you, even with the app closed. Your phone will ask first.'**
  String get permFrame;

  /// Plain voice. Focus, once, after notifications are turned down.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off, so Tomo can\'t tell you when a block ends. Your blocks still count. The bell at the top opens your phone\'s settings.'**
  String get permDenied;

  /// Plain voice. Focus, the note when auto-start began the break.
  ///
  /// In en, this message translates to:
  /// **'Break started on its own. Auto-start is on (change it in Settings).'**
  String get autoNote;

  /// Plain voice. Home, the clock notice.
  ///
  /// In en, this message translates to:
  /// **'Your phone\'s clock moved back during a block, so that block couldn\'t count. Everything you finished before is safe.'**
  String get clock;

  /// Plain voice. Stop early sheet, title.
  ///
  /// In en, this message translates to:
  /// **'Stop this block?'**
  String get stopTitle;

  /// Plain voice. Stop early sheet, body.
  ///
  /// In en, this message translates to:
  /// **'Only finished blocks count, so this one won\'t. Everything you\'ve finished before stays.'**
  String get stopBody;

  /// Plain voice. Delete task sheet, title.
  ///
  /// In en, this message translates to:
  /// **'Delete this task?'**
  String get delTaskTitle;

  /// Plain voice. Delete task sheet, with under an hour of focus time.
  ///
  /// In en, this message translates to:
  /// **'\"{task}\" and its notes go for good. The {minutes} minutes you focused on it stay in your stats.'**
  String delTask(String task, int minutes);

  /// Plain voice. Delete task sheet, with an hour or more of focus time. {duration} is written as on Stats ("6 h 40 min").
  ///
  /// In en, this message translates to:
  /// **'\"{task}\" and its notes go for good. The {duration} you focused on it stays in your stats.'**
  String delTaskLong(String task, String duration);

  /// Plain voice. Delete task sheet, no focus time.
  ///
  /// In en, this message translates to:
  /// **'\"{task}\" and its notes go for good. It has no focus time, so your stats don\'t change.'**
  String delTaskNone(String task);

  /// Plain voice. Delete project sheet, title.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{project}\"?'**
  String delProjTitle(String project);

  /// Plain voice. Delete project sheet, with tasks. {duration} is written as on Stats ("6 h 40 min").
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Its 1 task goes with it, for good. The {duration} you focused on it stays in your stats.} other{Its {count} tasks go with it, for good. The {duration} you focused on them stays in your stats.}}'**
  String delProj(int count, String duration);

  /// Plain voice. Delete project sheet, with tasks but no focus time.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Its 1 task goes with it, for good. It has no focus time, so your stats don\'t change.} other{Its {count} tasks go with it, for good. They have no focus time, so your stats don\'t change.}}'**
  String delProjNoFocus(int count);

  /// Plain voice. Delete project sheet, no tasks.
  ///
  /// In en, this message translates to:
  /// **'It has no tasks, so nothing else changes.'**
  String get delProjNone;

  /// Plain voice. Task lock, under the ring, Done or Delete.
  ///
  /// In en, this message translates to:
  /// **'A block is running on this task. Stop it or let it finish first.'**
  String get lockTask;

  /// Plain voice. Task lock, under Delete project.
  ///
  /// In en, this message translates to:
  /// **'A block is running on a task in this project. Stop it or let it finish first.'**
  String get lockProject;

  /// Plain voice. Work, no projects, title.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get emptyProjectsTitle;

  /// Plain voice. Work, no projects, line.
  ///
  /// In en, this message translates to:
  /// **'A project holds the tasks for one piece of work, like a thesis or a move.'**
  String get emptyProjects;

  /// Plain voice. Empty project, title.
  ///
  /// In en, this message translates to:
  /// **'Nothing in {project} yet'**
  String emptyProjectTitle(String project);

  /// Plain voice. Empty project, line.
  ///
  /// In en, this message translates to:
  /// **'Add the first task. You can focus on it from here or from Home.'**
  String get emptyProject;

  /// Plain voice. Project, everything done.
  ///
  /// In en, this message translates to:
  /// **'Everything in {project} is done.'**
  String allDone(String project);

  /// Plain voice. Task detail, a done task.
  ///
  /// In en, this message translates to:
  /// **'To focus on this again, set it back to To do.'**
  String get doneTask;

  /// Plain voice. Task detail, another task's block running.
  ///
  /// In en, this message translates to:
  /// **'A block is running on \"{task}\". Stop it or let it finish first.'**
  String otherRunning(String task);

  /// Plain voice. Settings > About.
  ///
  /// In en, this message translates to:
  /// **'Tomo never connects to the internet. Your pet and tasks are kept in your phone\'s own backup. Moving between iPhone and Android doesn\'t bring them across.'**
  String get about;

  /// Plain voice. Settings > About, crash reports.
  ///
  /// In en, this message translates to:
  /// **'Your phone may send crash reports to Apple or Google if its settings allow it. Tomo never sees them.'**
  String get aboutOs;

  /// Plain voice. Settings > About, under Share diagnostics.
  ///
  /// In en, this message translates to:
  /// **'A list of errors, with no tasks, names or notes in it. You choose where it goes.'**
  String get shareDiag;

  /// Plain voice. Error block (any screen).
  ///
  /// In en, this message translates to:
  /// **'Something went wrong here. If it keeps happening, Settings > About > Share diagnostics makes a report you can send.'**
  String get error;

  /// Plain voice. Custom sheet, title.
  ///
  /// In en, this message translates to:
  /// **'Custom length'**
  String get customTitle;

  /// Plain voice. Custom sheet, focus stepper.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get customFocus;

  /// Plain voice. Custom sheet, break stepper.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get customBreak;

  /// Plain voice. Custom sheet, button.
  ///
  /// In en, this message translates to:
  /// **'Use these'**
  String get customUse;

  /// Plain voice. Length chip, while a custom pair is chosen. Two lines, so the three chips stay one row.
  ///
  /// In en, this message translates to:
  /// **'Custom\n{minutes} min'**
  String customChip(int minutes);

  /// Plain voice. Focus time under an hour, as on Stats ("15 min").
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String focusTimeMinutes(int minutes);

  /// Plain voice. Focus time in whole hours ("2 h").
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String focusTimeHours(int hours);

  /// Plain voice. Focus time of an hour or more, as on Stats ("26 h 40 min").
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String focusTimeHoursMinutes(int hours, int minutes);

  /// Plain voice. Choice after a finished block or break.
  ///
  /// In en, this message translates to:
  /// **'Start another task'**
  String get startAnotherTask;

  /// Screen reader. The pet, read when touched.
  ///
  /// In en, this message translates to:
  /// **'{name}, level {level}. {exp} of 600 EXP toward level {nextLevel}. Stage {stage} of 4.'**
  String srPet(String name, int level, int exp, int nextLevel, int stage);

  /// Screen reader. The egg, read when touched. It names only the egg (#114).
  ///
  /// In en, this message translates to:
  /// **'{eggName}. It hatches when you finish a focus block.'**
  String srEgg(String eggName);

  /// Screen reader. The quiet clock, read when touched.
  ///
  /// In en, this message translates to:
  /// **'About {minutes} {minutes, plural, =1{minute} other{minutes}} left on {task}.'**
  String srClock(int minutes, String task);

  /// Screen reader. A run: the block.
  ///
  /// In en, this message translates to:
  /// **'Block done: {minutes} minutes on {task}.'**
  String srRunBlock(int minutes, String task);

  /// Screen reader. A run: the task done.
  ///
  /// In en, this message translates to:
  /// **'Task done: {task}.'**
  String srRunTask(String task);

  /// Screen reader. A run: the hatch.
  ///
  /// In en, this message translates to:
  /// **'Your egg hatched.'**
  String get srRunHatch;

  /// Screen reader. A run: what was gained.
  ///
  /// In en, this message translates to:
  /// **'{name} gained {exp} EXP.'**
  String srRunGained(String name, int exp);

  /// Screen reader. A run: what was gained, with a level reached.
  ///
  /// In en, this message translates to:
  /// **'{name} gained {exp} EXP and reached level {level}.'**
  String srRunGainedLevel(String name, int exp, int level);

  /// Screen reader. A run: what was gained, with a level and a stage reached.
  ///
  /// In en, this message translates to:
  /// **'{name} gained {exp} EXP, reached level {level} and grew to stage {stage} of 4.'**
  String srRunGainedLevelStage(String name, int exp, int level, int stage);

  /// Screen reader. A run: the pet's name and its shown line.
  ///
  /// In en, this message translates to:
  /// **'{name}: {line}'**
  String srRunPetLine(String name, String line);

  /// Tab bar. The Home tab (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// Tab bar. The Work tab (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get tabWork;

  /// Screen reader. The back arrow at the top left of a screen.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Onboarding 1, the button to the second screen (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// Onboarding 2, the primary button (approved on Tomo Pixel Screens). Turned off while the field is empty.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get onboardingDone;

  /// Onboarding 2, the quiet button that finishes without a task (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// The name of the one project onboarding makes when the user skips "What are you working on?" (chosen by the user, spec §17).
  ///
  /// In en, this message translates to:
  /// **'My work'**
  String get defaultProject;

  /// Home's primary button, and Focus Ready's (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Start focusing'**
  String get startFocusing;

  /// Home, the level chip at the top left that opens Stats (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Lv {level}'**
  String levelChip(int level);

  /// Screen reader. Home's level chip, which opens Stats.
  ///
  /// In en, this message translates to:
  /// **'Level {level}. Stats'**
  String srLevelChip(int level);

  /// Under the EXP bar: EXP toward the next level (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'{exp} / 600 EXP'**
  String expLine(int exp);

  /// Screen reader. Home's gear, which opens Settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Screen reader. The close (×) on a notice, such as Home's clock notice (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Rises beside the pet as a block or a task's bonus is counted (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'+{exp} EXP'**
  String beatGain(int exp);

  /// The plate under the EXP bar at a level-up (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String beatLevelPlate(int level);

  /// The plate under the EXP bar when a task is marked done on Focus (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Task done'**
  String get beatTaskPlate;

  /// Screen reader. The close (×) at the top left of Focus Ready, which leaves Focus (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get focusLeave;

  /// Screen reader. The bell-off at the top right of Focus, which opens the phone's settings (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Notifications are off'**
  String get bellOff;

  /// Focus Ready, the caption over the task row, which opens the task picker (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get readyTask;

  /// Focus Ready, the caption over 25 min / 50 min / Custom (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get readyLength;

  /// A block or break length: the 25 min and 50 min choices on Focus Ready, and the Custom sheet's steppers (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String lengthMinutes(int minutes);

  /// Focus Ready, the third length choice while a preset is chosen (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get lengthCustom;

  /// Screen reader. The − of a stepper (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Fewer'**
  String get stepFewer;

  /// Screen reader. The + of a stepper (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get stepMore;

  /// The task picker's title.
  ///
  /// In en, this message translates to:
  /// **'Choose a task'**
  String get pickerTitle;

  /// The task picker, the field that adds a task and goes to Focus (spec §8.1).
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTask;

  /// Screen reader. The task picker's project chip, under New task.
  ///
  /// In en, this message translates to:
  /// **'Goes in {project}. Change project'**
  String srNewTaskProject(String project);

  /// The sheet the task picker's project chip opens: the project New task goes in.
  ///
  /// In en, this message translates to:
  /// **'Choose a project'**
  String get chooseProject;

  /// The chip on a doing task's row (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Doing'**
  String get statusDoing;

  /// Screen reader. The chevron at Focus's top left while a cycle is live: back to the app, with the banner (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Minimise'**
  String get minimise;

  /// Focus, a block running: the quiet clock, in rough minutes (ADR-0010, approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'about {minutes} min left'**
  String clockLeft(int minutes);

  /// Focus, a block's last minute: the quiet clock (ADR-0010). Also the banner's.
  ///
  /// In en, this message translates to:
  /// **'under a minute left'**
  String get clockUnderMinute;

  /// Focus, a break running: the quiet clock (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'about {minutes} min of rest left'**
  String restLeft(int minutes);

  /// Focus, a break's last minute: the quiet clock (spec §17 small call, after ADR-0010's 'under a minute left').
  ///
  /// In en, this message translates to:
  /// **'under a minute of rest left'**
  String get restUnderMinute;

  /// Focus, a block running: the accent chip under the progress line (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get chipFocus;

  /// Focus, a break running: the muted chip under the progress line (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get chipBreak;

  /// Focus, a block running: the quiet button at the bottom, and the destructive button on the Stop this block? sheet (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Stop early'**
  String get stopEarly;

  /// The Stop this block? sheet: the primary button, which closes it (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get keepGoing;

  /// Focus, a break running: ends it now; lands on Break over (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Skip break'**
  String get skipBreak;

  /// Focus, next block in 10: starts the block at once (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Start now'**
  String get startNow;

  /// Focus, next block in 10: stops the countdown and stays on Break over; and the estimate card's secondary button, which puts the card away (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// The running banner, under the task, while a block runs (ADR-0010, approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'{minutes} min left'**
  String bannerLeft(int minutes);

  /// The running banner, under the task, while a break runs (spec §8.4).
  ///
  /// In en, this message translates to:
  /// **'Break · about {minutes} min'**
  String bannerBreak(int minutes);

  /// The running banner, a break's last minute (spec §17 small call).
  ///
  /// In en, this message translates to:
  /// **'Break · under a minute'**
  String get bannerBreakUnderMinute;

  /// The finished banner: a block ended while Focus was minimised; its beat waits for the tap (approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Block done · {minutes} min counted'**
  String bannerBlockDone(int minutes);

  /// The finished banner: the break ended while Focus was minimised (spec §8.3).
  ///
  /// In en, this message translates to:
  /// **'Break over'**
  String get bannerBreakOver;

  /// Screen reader. The quiet clock in a block's last minute, read when touched (spec §17 small call, after srClock).
  ///
  /// In en, this message translates to:
  /// **'Under a minute left on {task}.'**
  String srClockUnderMinute(String task);

  /// Screen reader. The quiet clock during a break, read when touched (spec §17 small call, after srClock).
  ///
  /// In en, this message translates to:
  /// **'About {minutes} {minutes, plural, =1{minute} other{minutes}} of rest left.'**
  String srRest(int minutes);

  /// Screen reader. The quiet clock in a break's last minute (spec §17 small call).
  ///
  /// In en, this message translates to:
  /// **'Under a minute of rest left.'**
  String get srRestUnderMinute;

  /// Focus, after a block: the primary choice, with the cycle's own break length (spec §8.5; approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Take a {minutes}-min break'**
  String choiceBreak(int minutes);

  /// Focus, after a block: another block on the same task, with the cycle's own focus length (spec §8.5; approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Another {minutes}-min block'**
  String choiceAnotherBlock(int minutes);

  /// Focus, break over: another block on the same task (spec §8.5; approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Start another block'**
  String get startAnotherBlock;

  /// Focus, after a block or a break: marks the cycle's task done (spec §8.5; approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Mark task done'**
  String get markTaskDone;

  /// Focus, after a block or a break: ends the cycle (Leave) and closes Focus (spec §8.5; approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Done for now'**
  String get doneForNow;

  /// Focus, the estimate card's title, above the pet's fact line (spec §8.4; approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Is this task done?'**
  String get estimateTitle;

  /// Focus, the estimate card's primary button: marks the task done (spec §8.4; approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get estimateMarkDone;

  /// The hatch, the label over the name field, pre-filled with the species name. It says what hatched, since the egg kept it a surprise (#114).
  ///
  /// In en, this message translates to:
  /// **'Name your {speciesName}'**
  String hatchName(String speciesName);

  /// The hatch, the one button: keeps the name and goes back to Focus's choices (spec §8.7; approved on Tomo Pixel Screens).
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get hatchDone;

  /// The Work tab's title (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get workTitle;

  /// Work: the + at the top right (screen reader), the sheet it opens (title), and the button on the no-projects card (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get newProject;

  /// The New project sheet's button, which makes the project and opens it (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Create project'**
  String get createProject;

  /// Screen reader. The field on the New project and Rename project sheets.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectName;

  /// Under a project's name, on its Work row and in its header, when some tasks are open (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'{open} open · {done} done'**
  String projectCounts(int open, int done);

  /// Under a project's name when every task is done (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'All {count} done'**
  String projectAllDone(int count);

  /// Under a project's name when it has no tasks (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get projectNoTasks;

  /// Screen reader. The ⋯ in a project's header, which opens Rename project and Delete project.
  ///
  /// In en, this message translates to:
  /// **'Project options'**
  String get projectOptions;

  /// The project menu's first row, and the title of the sheet it opens (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Rename project'**
  String get renameProject;

  /// The Rename project sheet's button (spec §17 small call; the approved screens don't show the sheet).
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameSave;

  /// The project menu's red row, and the destructive button on its Delete sheet (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get deleteProject;

  /// The field at the end of a project's open tasks: type a title, Enter adds it (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Add a task'**
  String get addTask;

  /// A task row's meta: finished blocks out of the planned ones, at or under the plan (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'{planned, plural, =1{{done} of 1 block} other{{done} of {planned} blocks}}'**
  String taskBlocksOfPlan(int done, int planned);

  /// A task row's meta: more blocks finished than planned. No colour, warning or 'over' word (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'{done} blocks · planned {planned}'**
  String taskBlocksOverPlan(int done, int planned);

  /// A task row's meta: finished blocks, no plan (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 block} other{{count} blocks}}'**
  String taskBlocks(int count);

  /// Screen reader. The ⋯ at the end of a task row, which opens the row menu (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Task options'**
  String get taskOptions;

  /// Screen reader. An open task's status ring: its status, then what a tap does (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'{status}. Mark done'**
  String srRingMarkDone(String status);

  /// Screen reader. A done task's status ring: a tap reopens it (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Done. Reopen'**
  String get srRingReopen;

  /// The status control's first option, and a to-do ring's status (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get statusTodo;

  /// The status control's last option (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// The row menu: opens Move to project (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Move to another project'**
  String get moveToAnotherProject;

  /// The sheet that lists every project, the task's own checked (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Move to project'**
  String get moveToProject;

  /// The row menu's red row, and the destructive button on the Delete this task? sheet (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get deleteTask;

  /// A Delete sheet's secondary button, above Delete (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Screen reader. Task detail's title field, which has no label on screen (spec §17 C144).
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get taskTitleField;

  /// Task detail, the empty notes field (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Add notes'**
  String get addNotes;

  /// Screen reader. Task detail's notes field, which has no label on screen (spec §17 C144).
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesField;

  /// Task detail, the label over the project row (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get detailProject;

  /// Task detail, the label over the status control (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get detailStatus;

  /// Task detail, the label over the stepper (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Planned blocks'**
  String get plannedBlocks;

  /// Task detail, the stepper with no planned blocks (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'No plan'**
  String get noPlan;

  /// Task detail, the label over what focusing has done (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Focus so far'**
  String get focusSoFar;

  /// Task detail, Focus so far with no finished block (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get focusSoFarNone;

  /// Task detail, Focus so far: the task's finished blocks and their time, written as Stats writes it (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'{blocks, plural, =1{1 block} other{{blocks} blocks}} · {duration}'**
  String focusSoFarDone(int blocks, String duration);

  /// Task detail, in place of Start focusing while this task's block runs (approved on Tomo Task Screens).
  ///
  /// In en, this message translates to:
  /// **'Back to focus'**
  String get backToFocus;

  /// Stats, the screen's title (approved on Tomo Stats Screen).
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTitle;

  /// Stats, the first row's label (approved on Tomo Stats Screen).
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get statLevel;

  /// Stats, the row of every finished block's minutes (approved on Tomo Stats Screen).
  ///
  /// In en, this message translates to:
  /// **'Time focused'**
  String get statTimeFocused;

  /// Stats, the row counting finished blocks (approved on Tomo Stats Screen).
  ///
  /// In en, this message translates to:
  /// **'Blocks finished'**
  String get statBlocks;

  /// Stats, the row counting days with a finished block (approved on Tomo Stats Screen).
  ///
  /// In en, this message translates to:
  /// **'Days focused'**
  String get statDays;

  /// Settings, the label over Rename pet and Calm pet (spec §8.10).
  ///
  /// In en, this message translates to:
  /// **'Pet'**
  String get settingsPet;

  /// Settings, the row that opens the Rename pet sheet, and the sheet's title (spec §8.10).
  ///
  /// In en, this message translates to:
  /// **'Rename pet'**
  String get renamePet;

  /// Screen reader. The field on the Rename pet sheet.
  ///
  /// In en, this message translates to:
  /// **'Pet\'s name'**
  String get petNameField;

  /// Settings, the switch that stills the pet between celebrations (spec §7.7, §8.10).
  ///
  /// In en, this message translates to:
  /// **'Calm pet'**
  String get calmPet;

  /// Plain voice. Settings, under Calm pet.
  ///
  /// In en, this message translates to:
  /// **'Your pet stays still, apart from celebrations.'**
  String get calmPetAbout;

  /// Settings, the label over Auto-start (spec §8.10).
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get settingsFocus;

  /// Settings, the switch that starts breaks, and the next block from Focus, by themselves (spec §4.8, §8.10).
  ///
  /// In en, this message translates to:
  /// **'Auto-start'**
  String get autoStart;

  /// Plain voice. Settings, under Auto-start (spec §4.8).
  ///
  /// In en, this message translates to:
  /// **'When a block ends, the break starts by itself.'**
  String get autoStartAbout;

  /// Settings, the label over the notification status (spec §8.10).
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// Plain voice. Settings, the phone lets Tomo post notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications are on'**
  String get notifStatusOn;

  /// Plain voice. Settings, the phone hasn't asked about notifications yet (spec §11.4).
  ///
  /// In en, this message translates to:
  /// **'Not asked yet. Your phone will ask when you start your first block.'**
  String get notifStatusNotAsked;

  /// Settings, the row that opens the phone's notification settings for Tomo (spec §8.10).
  ///
  /// In en, this message translates to:
  /// **'Open system settings'**
  String get openSystemSettings;

  /// Settings, the label over the theme control (spec §8.10).
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Settings, Appearance: follow the phone's light or dark setting (spec §8.10).
  ///
  /// In en, this message translates to:
  /// **'Match phone'**
  String get appearanceSystem;

  /// Settings, Appearance (spec §8.10).
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// Settings, Appearance (spec §8.10).
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// Settings, the label over the version, licences and Share diagnostics (spec §8.10).
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Settings, About: the label beside the app's version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Settings, About: the app's version and build number, as "1.0.0 (1)".
  ///
  /// In en, this message translates to:
  /// **'{version} ({build})'**
  String versionNumber(String version, String build);

  /// Settings, About: the row that opens the licences of the code and the font Tomo uses, and that screen's title.
  ///
  /// In en, this message translates to:
  /// **'Licences'**
  String get licences;

  /// Licences: under a package's name, how many licences it has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 licence} other{{count} licences}}'**
  String licenceCount(int count);

  /// Settings, About: the button that hands the diagnostic log to the phone's share sheet (spec §13).
  ///
  /// In en, this message translates to:
  /// **'Share diagnostics'**
  String get shareDiagnostics;

  /// Plain voice. Settings, About: how many entries the diagnostic log holds, beside Share diagnostics. The button is off at zero.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No errors recorded} =1{1 error recorded} other{{count} errors recorded}}'**
  String diagEntries(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

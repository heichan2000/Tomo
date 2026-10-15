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
  /// **'{species, select, geode{{minutesWords} minutes. They stay.} joe{{minutes} of {minutes} minutes. Counted!} lily{You stayed with it the whole way, didn\'t you?} other{}}'**
  String blockDone(String species, int minutes, String minutesWords);

  /// Pet voice, Chatty. Block done, when this task has 2 or more blocks.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{{minutesWords} minutes. {taskMinutesWords} on {task} now, all of it in me.} joe{{minutes} of {minutes} minutes. Counted! Block {taskBlocks} on {task}.} lily{You stayed with it the whole way, didn\'t you? That\'s {taskBlocks} blocks you\'ve given {task}.} other{}}'**
  String blockDoneChattyTaskTotal(
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
  /// **'{species, select, geode{Level {levelWords}. Another hour in me.} joe{Level {level}! Up from {levelBefore}.} lily{Level {level}. You did that, you know?} other{}}'**
  String levelUp(String species, int level, String levelWords, int levelBefore);

  /// Pet voice, Chatty. Level-up, with the total time focused.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{Level {levelWords}. {hoursWords} {hours, plural, =1{hour} other{hours}} in me now, layer on layer.} joe{Level {level}! Up from {levelBefore}. {totalMinutes} minutes of focus, all counted.} lily{Level {level}. That\'s {hours} {hours, plural, =1{hour} other{hours}} you\'ve focused. Can you believe it?} other{}}'**
  String levelUpChattyTotalTime(
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
  /// **'{species, select, geode{I am bigger. All of me is still here.} joe{Stage {stage} of 4!} lily{Look at me! You did this, didn\'t you?} other{}}'**
  String evolution(String species, int stage);

  /// Pet voice, Chatty. Evolution, with the total time focused.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{I am bigger. {hoursWords} hours, and this is what they make. All of me is still here.} joe{Stage {stage} of 4! Folded from {hours} hours of focus.} lily{Look at me! {hours} hours of your focus did this, didn\'t they?} other{}}'**
  String evolutionChattyTotalTime(
    String species,
    int stage,
    int hours,
    String hoursWords,
  );

  /// Pet voice. A task was marked done.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{{task} is done. It stays done.} joe{Done: {task}!} lily{You finished {task}. Feels good, doesn\'t it?} other{}}'**
  String taskDone(String species, String task);

  /// Pet voice, Chatty. Task done, when the task has focus time.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{{task} is done. {taskMinutesWords} minutes are in it, and they stay.} joe{Done: {task}! {taskBlocks} {taskBlocks, plural, =1{block} other{blocks}}, {taskMinutes} minutes.} lily{You finished {task}, all {taskBlocks} blocks of it. Feels good, doesn\'t it?} other{}}'**
  String taskDoneChattyTaskTotal(
    String species,
    String task,
    int taskBlocks,
    int taskMinutes,
    String taskMinutesWords,
  );

  /// Pet voice. A break is running. (The script calls this key "break", a word Dart keeps for itself.)
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{A break. Everything is still here.} joe{Break: {breakMinutes} {breakMinutes, plural, =1{minute} other{minutes}}.} lily{You\'re resting. Nice, isn\'t it?} other{}}'**
  String onBreak(String species, int breakMinutes);

  /// Pet voice, Chatty. On a break, with what was finished today.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{A break. {todayMinutesWords} minutes today, and everything is still here.} joe{Break: {breakMinutes} {breakMinutes, plural, =1{minute} other{minutes}}. {todayBlocks} {todayBlocks, plural, =1{block} other{blocks}} done today.} lily{You\'re resting after {todayBlocks} {todayBlocks, plural, =1{block} other{blocks}} today. Nice, isn\'t it?} other{}}'**
  String onBreakChattyToday(
    String species,
    int breakMinutes,
    int todayBlocks,
    String todayMinutesWords,
  );

  /// Pet voice. The break has ended.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{The break is whole. I am here.} joe{Break done: {breakMinutes} of {breakMinutes} {breakMinutes, plural, =1{minute} other{minutes}}.} lily{You\'re back. A bit rested now, aren\'t you?} other{}}'**
  String breakOver(String species, int breakMinutes);

  /// Pet voice, Chatty. Break over, with what was finished today.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{The break is whole. {todayMinutesWords} minutes today, and I am here.} joe{Break done: {breakMinutes} of {breakMinutes} {breakMinutes, plural, =1{minute} other{minutes}}. {todayBlocks} {todayBlocks, plural, =1{block} other{blocks}} so far today.} lily{You\'re back, with {todayBlocks} {todayBlocks, plural, =1{block} other{blocks}} behind you today. A bit rested now, aren\'t you?} other{}}'**
  String breakOverChattyToday(
    String species,
    int breakMinutes,
    int todayBlocks,
    String todayMinutesWords,
  );

  /// Pet voice. The hatch line, after the first finished block.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{{minutesWords} minutes. I am made of them.} joe{Hello! 1 block, {minutes} minutes, 1 me.} lily{Oh! It was you, wasn\'t it?} other{}}'**
  String hatch(String species, int minutes, String minutesWords);

  /// Pet voice, Chatty. The hatch line, with the first block's task.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{{minutesWords} minutes of {task}. I am made of them.} joe{Hello! 1 block, {minutes} minutes on {task}, 1 me. First of everything!} lily{Oh! It was you, wasn\'t it? {minutes} minutes on {task}, and here I am.} other{}}'**
  String hatchChattyFirstBlock(
    String species,
    int minutes,
    String minutesWords,
    String task,
  );

  /// Pet voice. A pet's description on onboarding's first screen.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{I am Geode. I keep every minute.} joe{Joe. 1 paper bird. I count.} lily{I\'m Lily. I\'d like to know you.} other{}}'**
  String setup(String species);

  /// Pet voice, Chatty. The description when Chatty is selected.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{I am Geode. I keep every minute of focus, layer on layer, and I like to say so.} joe{I\'m Joe! 1 paper bird who counts every block and every minute, out loud.} lily{I\'m Lily! I notice every block you finish, and I tell you about it. You don\'t mind, do you?} other{}}'**
  String setupChatty(String species);

  /// Pet voice. The egg's line on Home.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{I am in here. A finished focus block opens me.} joe{1 egg. 1 focus block to hatch.} lily{I hatch when you finish a focus block. Shall we?} other{}}'**
  String egg(String species);

  /// Pet voice. A block finished while the user was away. {time} is a time of day as this phone writes it.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{{time}: the block is whole, with no one watching. {minutesWords} minutes, counted.} joe{Finished at {time}. {minutes} of {minutes} minutes, counted.} lily{Your block finished at {time} while you were away. All {minutes} minutes count.} other{}}'**
  String awayNote(
    String species,
    String time,
    int minutes,
    String minutesWords,
  );

  /// Pet voice. The auto-start countdown, in seconds.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{The next block begins in {secondsWords}.} joe{Next block in {seconds}.} lily{Your next block starts in {seconds}. Ready?} other{}}'**
  String countdown(String species, int seconds, String secondsWords);

  /// Pet voice. The estimate card's fact line.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{Every planned block is here.} joe{{estimate} of {estimate} planned {estimate, plural, =1{block} other{blocks}}.} lily{That\'s all {estimate} {estimate, plural, =1{block} other{blocks}} you planned for it.} other{}}'**
  String estimate(String species, int estimate);

  /// A notification's title before the hatch.
  ///
  /// In en, this message translates to:
  /// **'Your egg'**
  String get notifTitleEgg;

  /// Notification body. A focus block ended.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{{minutesWords} minutes of {task}. They are counted.} joe{{task}: {minutes} of {minutes} minutes, counted.} lily{You gave {task} {minutes} minutes. Every one of them counted.} other{}}'**
  String notifBlockDone(
    String species,
    String task,
    int minutes,
    String minutesWords,
  );

  /// Notification body. A focus block ended and auto-start began the break.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{{minutesWords} minutes of {task}, counted. The break is here.} joe{{task}: {minutes} of {minutes} minutes, counted. Break started: {breakMinutes} {breakMinutes, plural, =1{minute} other{minutes}}.} lily{You gave {task} {minutes} minutes, and they all counted. Your break has begun.} other{}}'**
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
  /// **'{species, select, geode{The break is whole. I am here.} joe{Break finished: {breakMinutes} of {breakMinutes} {breakMinutes, plural, =1{minute} other{minutes}}.} lily{Your break is over. Did you stretch? Either way, it was yours.} other{}}'**
  String notifBreakOver(String species, int breakMinutes);

  /// Notification body. The first block ended, before the hatch.
  ///
  /// In en, this message translates to:
  /// **'{species, select, geode{{minutesWords} minutes of {task}, counted. My shell is cracking.} joe{{task}: {minutes} of {minutes} minutes, counted. My shell: 5 cracks.} lily{You gave {task} {minutes} minutes, and my shell is cracking. Who\'s in here, I wonder?} other{}}'**
  String notifFirstBlock(
    String species,
    String task,
    int minutes,
    String minutesWords,
  );

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

  /// Plain voice. Onboarding 1, title.
  ///
  /// In en, this message translates to:
  /// **'Choose your pet'**
  String get pickTitle;

  /// Plain voice. Onboarding 1, line.
  ///
  /// In en, this message translates to:
  /// **'You keep this one. It hatches from an egg when you finish your first focus block.'**
  String get pickLine;

  /// Plain voice. Onboarding 1, personality label.
  ///
  /// In en, this message translates to:
  /// **'Personality'**
  String get persLabel;

  /// Plain voice. Onboarding 1, under Quiet / Chatty.
  ///
  /// In en, this message translates to:
  /// **'How much your pet says. You can change it in Settings.'**
  String get persHint;

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

  /// Plain voice. Delete task sheet, with focus time.
  ///
  /// In en, this message translates to:
  /// **'\"{task}\" and its notes go for good. The {minutes} minutes you focused on it stay in your stats.'**
  String delTask(String task, int minutes);

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
  /// **'{count, plural, =1{Its 1 task goes with it, for good.} other{Its {count} tasks go with it, for good.}} The {duration} you focused on them stays in your stats.'**
  String delProj(int count, String duration);

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

  /// Plain voice. Length chip, while a custom pair is chosen.
  ///
  /// In en, this message translates to:
  /// **'Custom · {minutes} min'**
  String customChip(int minutes);

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

  /// Screen reader. The egg, read when touched.
  ///
  /// In en, this message translates to:
  /// **'{speciesName} egg. It hatches when you finish a focus block.'**
  String srEgg(String speciesName);

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

  /// Personality control, the Quiet option (onboarding and Settings).
  ///
  /// In en, this message translates to:
  /// **'Quiet'**
  String get persQuiet;

  /// Personality control, the Chatty option (onboarding and Settings).
  ///
  /// In en, this message translates to:
  /// **'Chatty'**
  String get persChatty;

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

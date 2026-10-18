import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/l10n/app_localizations.dart';
import 'package:tomo/voice/pet_voice.dart';
import 'package:tomo_core/notifications/notification_schedule.dart';
import 'package:tomo_core/pet/beat.dart';
import 'package:tomo_core/pet/personality.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/voice/pet_moment.dart';

/// Every line is held to the approved script, word for word: the expected
/// text below is copied from
/// https://github.com/heichan2000/Tomo/issues/51#issuecomment-6052038890
/// and uses its sample (a 25-minute block on "Write the intro", 3 blocks and
/// 75 minutes so far, level 8, stage 2, a 15-minute first block).
void main() {
  final l = lookupAppLocalizations(const Locale('en'));
  const task = 'Write the intro';
  const geode = Species.geode;
  const joe = Species.joe;
  const lily = Species.lily;

  String quiet(PetMoment moment, Species species) => petLine(
    l,
    moment: moment,
    species: species,
    personality: Personality.quiet,
  );
  String chatty(PetMoment moment, Species species) => petLine(
    l,
    moment: moment,
    species: species,
    personality: Personality.chatty,
  );

  /// Checks one row of the script: the three pets, Quiet then Chatty.
  void row(
    String name,
    PetMoment moment, {
    required List<String> quietLines,
    List<String>? chattyLines,
  }) {
    test('$name, Quiet', () {
      expect([
        quiet(moment, geode),
        quiet(moment, joe),
        quiet(moment, lily),
      ], quietLines);
    });
    test('$name, Chatty', () {
      expect([
        chatty(moment, geode),
        chatty(moment, joe),
        chatty(moment, lily),
      ], chattyLines ?? quietLines);
    });
  }

  const blockDone = BlockDoneMoment(
    minutes: 25,
    task: task,
    taskBlocks: 3,
    taskMinutes: 75,
  );
  const levelUp = LevelUpMoment(level: 8, levelBefore: 7, totalMinutes: 425);
  const evolution = EvolutionMoment(stage: 2, totalMinutes: 540);
  const taskDone = TaskDoneMoment(task: task, taskBlocks: 4, taskMinutes: 100);
  const onBreak = OnBreakMoment(
    breakMinutes: 5,
    todayBlocks: 3,
    todayMinutes: 75,
  );
  const breakOver = BreakOverMoment(
    breakMinutes: 5,
    todayBlocks: 3,
    todayMinutes: 75,
  );
  const hatch = HatchMoment(minutes: 15, task: task);
  const away = AwayNoteMoment(time: '2:25 PM', minutes: 25);
  const countdown = CountdownMoment(seconds: 10);
  const estimate = EstimateMoment(estimate: 4);

  group('the script, word for word', () {
    row(
      'block done',
      blockDone,
      quietLines: [
        'Twenty-five minutes. They stay.',
        '25 of 25 minutes. Counted!',
        "You stayed with it the whole way, didn't you?",
      ],
      chattyLines: [
        'Twenty-five minutes. Seventy-five on Write the intro now, all of it '
            'in me.',
        '25 of 25 minutes. Counted! Block 3 on Write the intro.',
        "You stayed with it the whole way, didn't you? That's 3 blocks "
            "you've given Write the intro.",
      ],
    );
    row(
      'level-up',
      levelUp,
      quietLines: [
        'Level eight. Another hour in me.',
        'Level 8! Up from 7.',
        'Level 8. You did that, you know?',
      ],
      chattyLines: [
        'Level eight. Seven hours in me now, layer on layer.',
        'Level 8! Up from 7. 425 minutes of focus, all counted.',
        "Level 8. That's 7 hours you've focused. Can you believe it?",
      ],
    );
    row(
      'evolution',
      evolution,
      quietLines: [
        'I am bigger. All of me is still here.',
        'Stage 2 of 4!',
        "Look at me! You did this, didn't you?",
      ],
      chattyLines: [
        'I am bigger. Nine hours, and this is what they make. All of me is '
            'still here.',
        'Stage 2 of 4! Folded from 9 hours of focus.',
        "Look at me! 9 hours of your focus did this, didn't they?",
      ],
    );
    row(
      'task done',
      taskDone,
      quietLines: [
        'Write the intro is done. It stays done.',
        'Done: Write the intro!',
        "You finished Write the intro. Feels good, doesn't it?",
      ],
      chattyLines: [
        'Write the intro is done. One hundred minutes are in it, and they '
            'stay.',
        'Done: Write the intro! 4 blocks, 100 minutes.',
        "You finished Write the intro, all 4 blocks of it. Feels good, "
            "doesn't it?",
      ],
    );
    row(
      'break',
      onBreak,
      quietLines: [
        'A break. Everything is still here.',
        'Break: 5 minutes.',
        "You're resting. Nice, isn't it?",
      ],
      chattyLines: [
        'A break. Seventy-five minutes today, and everything is still here.',
        'Break: 5 minutes. 3 blocks done today.',
        "You're resting after 3 blocks today. Nice, isn't it?",
      ],
    );
    row(
      'break over',
      breakOver,
      quietLines: [
        'The break is whole. I am here.',
        'Break done: 5 of 5 minutes.',
        "You're back. A bit rested now, aren't you?",
      ],
      chattyLines: [
        'The break is whole. Seventy-five minutes today, and I am here.',
        'Break done: 5 of 5 minutes. 3 blocks so far today.',
        "You're back, with 3 blocks behind you today. A bit rested now, "
            "aren't you?",
      ],
    );
    row(
      'the hatch line',
      hatch,
      quietLines: [
        'Fifteen minutes. I am made of them.',
        'Hello! 1 block, 15 minutes, 1 me.',
        "Oh! It was you, wasn't it?",
      ],
      chattyLines: [
        'Fifteen minutes of Write the intro. I am made of them.',
        'Hello! 1 block, 15 minutes on Write the intro, 1 me. First of '
            'everything!',
        "Oh! It was you, wasn't it? 15 minutes on Write the intro, and here "
            'I am.',
      ],
    );
    row(
      'setup description',
      const SetupMoment(),
      quietLines: [
        'I am Geode. I keep every minute.',
        'Joe. 1 paper bird. I count.',
        "I'm Lily. I'd like to know you.",
      ],
      chattyLines: [
        'I am Geode. I keep every minute of focus, layer on layer, and I '
            'like to say so.',
        "I'm Joe! 1 paper bird who counts every block and every minute, out "
            'loud.',
        "I'm Lily! I notice every block you finish, and I tell you about it. "
            "You don't mind, do you?",
      ],
    );
    row(
      'Home egg line',
      const EggMoment(),
      quietLines: [
        'I am in here. A finished focus block opens me.',
        '1 egg. 1 focus block to hatch.',
        'I hatch when you finish a focus block. Shall we?',
      ],
    );
    row(
      'while you were away',
      away,
      quietLines: [
        '2:25 PM: the block is whole, with no one watching. Twenty-five '
            'minutes, counted.',
        'Finished at 2:25 PM. 25 of 25 minutes, counted.',
        'Your block finished at 2:25 PM while you were away. All 25 minutes '
            'count.',
      ],
    );
    row(
      'countdown line',
      countdown,
      quietLines: [
        'The next block begins in ten.',
        'Next block in 10.',
        'Your next block starts in 10. Ready?',
      ],
    );
    row(
      'estimate card fact',
      estimate,
      quietLines: [
        'Every planned block is here.',
        '4 of 4 planned blocks.',
        "That's all 4 blocks you planned for it.",
      ],
    );
  });

  // The cases the script had no line for, worded by the user in
  // https://github.com/heichan2000/Tomo/issues/85.
  group('lines added after the script', () {
    test('task done in one block: each pet counts it', () {
      const oneBlock = TaskDoneMoment(
        task: task,
        taskBlocks: 1,
        taskMinutes: 25,
      );

      expect(
        chatty(oneBlock, lily),
        "You finished Write the intro in just one block. Feels good, doesn't "
        'it?',
      );
      expect(
        chatty(oneBlock, joe),
        'Done: Write the intro! 1 block, 25 minutes.',
      );
      expect(
        chatty(oneBlock, geode),
        'Write the intro is done. Twenty-five minutes are in it, and they '
        'stay.',
      );
    });

    test('the estimate card, when the plan was one block', () {
      const one = EstimateMoment(estimate: 1);

      expect(
        [quiet(one, geode), quiet(one, joe), quiet(one, lily)],
        [
          'Every planned block is here.',
          '1 of 1 planned block.',
          "That's the one block you planned for it.",
        ],
      );
    });

    test('deleting a task: minutes under an hour, hours from an hour up', () {
      String body(int minutes) =>
          deleteTaskBody(l, task: 'Email Sam', minutes: minutes);

      expect(
        body(0),
        '"Email Sam" and its notes go for good. It has no focus time, so '
        "your stats don't change.",
      );
      expect(
        body(25),
        '"Email Sam" and its notes go for good. The 25 minutes you focused '
        'on it stay in your stats.',
      );
      expect(
        body(59),
        '"Email Sam" and its notes go for good. The 59 minutes you focused '
        'on it stay in your stats.',
      );
      expect(
        body(60),
        '"Email Sam" and its notes go for good. The 1 h you focused on it '
        'stays in your stats.',
      );
      expect(
        body(400),
        '"Email Sam" and its notes go for good. The 6 h 40 min you focused '
        'on it stays in your stats.',
      );
    });

    test('deleting a project', () {
      String body(int tasks, int minutes) =>
          deleteProjectBody(l, tasks: tasks, minutes: minutes);

      expect(body(0, 0), 'It has no tasks, so nothing else changes.');
      expect(
        body(7, 0),
        'Its 7 tasks go with it, for good. They have no focus time, so your '
        "stats don't change.",
      );
      expect(
        body(1, 0),
        'Its 1 task goes with it, for good. It has no focus time, so your '
        "stats don't change.",
      );
      expect(
        body(7, 400),
        'Its 7 tasks go with it, for good. The 6 h 40 min you focused on '
        'them stays in your stats.',
      );
      expect(
        body(1, 25),
        'Its 1 task goes with it, for good. The 25 min you focused on it '
        'stays in your stats.',
      );
    });
  });

  group('focus time, written as on Stats', () {
    test('minutes, whole hours, and hours with minutes', () {
      expect(focusTime(l, 15), '15 min');
      expect(focusTime(l, 59), '59 min');
      expect(focusTime(l, 120), '2 h');
      expect(focusTime(l, 1600), '26 h 40 min');
      expect(focusTime(l, 61), '1 h 1 min');
    });

    test('long totals group their digits', () {
      expect(focusTime(l, 1234 * 60 + 5), '1,234 h 5 min');
    });
  });

  group('Chatty falls back to Quiet when its detail is not true', () {
    test("block done on a task's first block", () {
      const first = BlockDoneMoment(
        minutes: 25,
        task: task,
        taskBlocks: 1,
        taskMinutes: 25,
      );

      for (final species in Species.values) {
        expect(chatty(first, species), quiet(first, species));
      }
    });

    test('task done on a task never focused on', () {
      const untouched = TaskDoneMoment(
        task: task,
        taskBlocks: 0,
        taskMinutes: 0,
      );

      for (final species in Species.values) {
        expect(chatty(untouched, species), quiet(untouched, species));
      }
    });

    test('a break after midnight, with nothing finished yet today', () {
      const newDay = OnBreakMoment(
        breakMinutes: 5,
        todayBlocks: 0,
        todayMinutes: 0,
      );

      for (final species in Species.values) {
        expect(chatty(newDay, species), quiet(newDay, species));
      }
    });

    test('a level-up before a whole hour has been focused', () {
      const early = LevelUpMoment(level: 2, levelBefore: 1, totalMinutes: 55);

      for (final species in Species.values) {
        expect(chatty(early, species), quiet(early, species));
      }
    });
  });

  group('one of something is said as one', () {
    test('one hour', () {
      const second = LevelUpMoment(level: 2, levelBefore: 1, totalMinutes: 60);

      expect(
        chatty(second, geode),
        'Level two. One hour in me now, layer on layer.',
      );
      expect(
        chatty(second, lily),
        "Level 2. That's 1 hour you've focused. Can you believe it?",
      );
    });

    test('one block today, a one-minute break', () {
      const short = OnBreakMoment(
        breakMinutes: 1,
        todayBlocks: 1,
        todayMinutes: 25,
      );

      expect(quiet(short, joe), 'Break: 1 minute.');
      expect(chatty(short, joe), 'Break: 1 minute. 1 block done today.');
      expect(
        chatty(short, lily),
        "You're resting after 1 block today. Nice, isn't it?",
      );
    });
  });

  group('the species rules no shading may erase', () {
    // Every moment, with numbers large and small, in both personalities.
    final moments = <PetMoment>[
      blockDone,
      const BlockDoneMoment(
        minutes: 120,
        task: task,
        taskBlocks: 12,
        taskMinutes: 1440,
      ),
      levelUp,
      const LevelUpMoment(level: 101, levelBefore: 100, totalMinutes: 6000),
      evolution,
      const EvolutionMoment(stage: 4, totalMinutes: 5940),
      taskDone,
      onBreak,
      const OnBreakMoment(breakMinutes: 30, todayBlocks: 9, todayMinutes: 450),
      breakOver,
      hatch,
      const SetupMoment(),
      const EggMoment(),
      // The time of day is the phone's own; it is not the pet's wording.
      const AwayNoteMoment(time: 'TIME', minutes: 50),
      countdown,
      const CountdownMoment(seconds: 3),
      estimate,
      const EstimateMoment(estimate: 20),
    ];
    // Task and project names are the user's words, not the pet's.
    final you = RegExp(
      r"\b(you|your|you're|you've|yours)\b",
      caseSensitive: false,
    );
    List<String> linesOf(Species species) => [
      for (final moment in moments) ...[
        quiet(moment, species).replaceAll(task, 'TASK'),
        chatty(moment, species).replaceAll(task, 'TASK'),
      ],
    ];

    test('Geode never says "you"', () {
      for (final line in linesOf(geode)) {
        expect(line, isNot(matches(you)), reason: line);
      }
    });

    test('Geode uses no digits: every number is spelled out', () {
      for (final line in linesOf(geode)) {
        expect(line, isNot(contains(RegExp(r'\d'))), reason: line);
      }
    });

    test('Joe never says "you"', () {
      for (final line in linesOf(joe)) {
        expect(line, isNot(matches(you)), reason: line);
      }
    });

    test('Joe counts in digits', () {
      for (final moment in [blockDone, levelUp, evolution, hatch, onBreak]) {
        expect(quiet(moment, joe), contains(RegExp(r'\d')));
      }
    });

    test('only Lily says "you", and she does', () {
      expect(linesOf(lily).where((line) => line.contains(you)), isNotEmpty);
    });

    test('every pet has a line for every moment', () {
      for (final species in Species.values) {
        for (final line in linesOf(species)) {
          expect(line.trim(), isNotEmpty);
        }
      }
    });
  });

  group('timer notifications', () {
    TimerNotification notification(
      NotificationKind kind, {
      Species species = geode,
      bool beforeHatch = false,
      String? petName = 'Pebble',
      int focusMinutes = 25,
    }) => TimerNotification(
      kind: kind,
      fireAt: DateTime.utc(2026),
      payload: '0',
      content: NotificationContent(
        species: species,
        beforeHatch: beforeHatch,
        petName: petName,
        taskTitle: task,
        focusMinutes: focusMinutes,
        breakMinutes: 5,
      ),
    );

    List<String> bodies(
      NotificationKind kind, {
      bool beforeHatch = false,
      int focusMinutes = 25,
    }) => [
      for (final species in Species.values)
        notificationText(
          l,
          notification(
            kind,
            species: species,
            beforeHatch: beforeHatch,
            focusMinutes: focusMinutes,
          ),
        ).body,
    ];

    test('block done', () {
      expect(bodies(NotificationKind.blockComplete), [
        'Twenty-five minutes of Write the intro. They are counted.',
        'Write the intro: 25 of 25 minutes, counted.',
        'You gave Write the intro 25 minutes. Every one of them counted.',
      ]);
    });

    test('block done, break begun', () {
      expect(bodies(NotificationKind.blockCompleteBreakBegun), [
        'Twenty-five minutes of Write the intro, counted. The break is here.',
        'Write the intro: 25 of 25 minutes, counted. Break started: 5 '
            'minutes.',
        'You gave Write the intro 25 minutes, and they all counted. Your '
            'break has begun.',
      ]);
    });

    test('break over', () {
      expect(bodies(NotificationKind.breakComplete), [
        'The break is whole. I am here.',
        'Break finished: 5 of 5 minutes.',
        'Your break is over. Did you stretch? Either way, it was yours.',
      ]);
    });

    test('the first block, before the hatch', () {
      expect(
        bodies(
          NotificationKind.blockComplete,
          beforeHatch: true,
          focusMinutes: 15,
        ),
        [
          'Fifteen minutes of Write the intro, counted. My shell is cracking.',
          'Write the intro: 15 of 15 minutes, counted. My shell: 5 cracks.',
          'You gave Write the intro 15 minutes, and my shell is cracking. '
              "Who's in here, I wonder?",
        ],
      );
    });

    test('the first block under auto-start still speaks of the hatch, and '
        'not the break (#85)', () {
      expect(
        bodies(
          NotificationKind.blockCompleteBreakBegun,
          beforeHatch: true,
          focusMinutes: 15,
        ),
        bodies(
          NotificationKind.blockComplete,
          beforeHatch: true,
          focusMinutes: 15,
        ),
      );
    });

    test("the title is the pet's name", () {
      expect(
        notificationText(l, notification(NotificationKind.blockComplete)).title,
        'Pebble',
      );
    });

    test('before the hatch the title is "Your egg"', () {
      expect(
        notificationText(
          l,
          notification(
            NotificationKind.blockComplete,
            beforeHatch: true,
            petName: null,
          ),
        ).title,
        'Your egg',
      );
    });

    test('a hatched pet with no name goes by its species', () {
      expect(
        notificationText(
          l,
          notification(
            NotificationKind.breakComplete,
            species: lily,
            petName: null,
          ),
        ).title,
        'Lily',
      );
    });

    test('the lines for hidden content', () {
      expect(l.notifHiddenBlock, 'A focus block counted.');
      expect(l.notifHiddenBreak, 'A break finished.');
      expect(l.notifPreviewsOff, 'Something you started has finished.');
    });

    test('no notification body has EXP, a level or a time of day in it', () {
      for (final kind in NotificationKind.values) {
        for (final beforeHatch in [true, false]) {
          for (final body in bodies(kind, beforeHatch: beforeHatch)) {
            expect(body, isNot(contains('EXP')), reason: body);
            expect(body.toLowerCase(), isNot(contains('level')), reason: body);
            expect(body, isNot(matches(RegExp(r'\b(AM|PM|today|now)\b'))));
          }
        }
      }
    });
  });

  group('plain voice', () {
    test('lines with a name or a number in them', () {
      expect(
        l.delTask('Email Sam about the draft', 25),
        '"Email Sam about the draft" and its notes go for good. The 25 '
        'minutes you focused on it stay in your stats.',
      );
      expect(
        l.delTaskNone('Email Sam about the draft'),
        '"Email Sam about the draft" and its notes go for good. It has no '
        "focus time, so your stats don't change.",
      );
      expect(l.delProjTitle('Thesis'), 'Delete "Thesis"?');
      expect(
        l.delProj(7, '6 h 40 min'),
        'Its 7 tasks go with it, for good. The 6 h 40 min you focused on '
        'them stays in your stats.',
      );
      expect(l.emptyProjectTitle('Spanish'), 'Nothing in Spanish yet');
      expect(l.allDone('Thesis'), 'Everything in Thesis is done.');
      expect(
        l.otherRunning('Write the intro'),
        'A block is running on "Write the intro". Stop it or let it finish '
        'first.',
      );
      expect(l.customChip(15), 'Custom · 15 min');
    });

    test('the lock lines end the same way', () {
      for (final line in [l.lockTask, l.lockProject, l.otherRunning('X')]) {
        expect(line, endsWith('Stop it or let it finish first.'));
      }
    });

    test('the privacy line says what Tomo does, and never "logged"', () {
      expect(l.about, startsWith('Tomo never connects to the internet.'));
      for (final line in [l.about, l.aboutOs, l.shareDiag, l.error]) {
        expect(line.toLowerCase(), isNot(contains('logged')));
      }
    });
  });

  group('what a screen reader is told', () {
    test('the pet, the egg and the clock', () {
      expect(
        l.srPet('Geode', 7, 480, 8, 1),
        'Geode, level 7. 480 of 600 EXP toward level 8. Stage 1 of 4.',
      );
      expect(
        l.srEgg(l.speciesName('geode')),
        'Geode egg. It hatches when you finish a focus block.',
      );
      expect(l.srClock(19, task), 'About 19 minutes left on Write the intro.');
      expect(l.srClock(1, task), 'About 1 minute left on Write the intro.');
    });

    String run(List<Beat> beats, PetMoment shown, {String? opening}) =>
        runAnnouncement(
          l,
          facts: RunFacts.of(beats, taskTitle: task),
          petName: 'Geode',
          petLine: quiet(shown, geode),
          opening: opening,
        );

    test('a run: block done', () {
      expect(
        run(const [BlockCredited(minutes: 25, exp: 250)], blockDone),
        'Block done: 25 minutes on Write the intro. Geode gained 250 EXP. '
        'Geode: Twenty-five minutes. They stay.',
      );
    });

    test('a run: block and level-up', () {
      expect(
        run(const [
          BlockCredited(minutes: 25, exp: 250),
          LevelUp(level: 8),
        ], levelUp),
        'Block done: 25 minutes on Write the intro. Geode gained 250 EXP and '
        'reached level 8. Geode: Level eight. Another hour in me.',
      );
    });

    test('a run: block, level-up and evolution', () {
      expect(
        run(const [
          BlockCredited(minutes: 25, exp: 250),
          LevelUp(level: 10),
          Evolution(from: 1, to: 2),
        ], evolution),
        'Block done: 25 minutes on Write the intro. Geode gained 250 EXP, '
        'reached level 10 and grew to stage 2 of 4. Geode: I am bigger. All '
        'of me is still here.',
      );
    });

    test('a run: task done', () {
      expect(
        run(const [TaskCompleted(bonusExp: 100)], taskDone),
        'Task done: Write the intro. Geode gained 100 EXP. Geode: Write the '
        'intro is done. It stays done.',
      );
    });

    test('a run: block done while away', () {
      expect(
        run(
          const [BlockCredited(minutes: 25, exp: 250)],
          blockDone,
          opening: quiet(away, geode),
        ),
        '2:25 PM: the block is whole, with no one watching. Twenty-five '
        'minutes, counted. Geode gained 250 EXP. Geode: Twenty-five minutes. '
        'They stay.',
      );
    });

    test('a run: the hatch', () {
      expect(
        run(const [
          BlockCredited(minutes: 15, exp: 150),
          Hatch(species: geode),
        ], hatch),
        'Your egg hatched. Geode: Fifteen minutes. I am made of them.',
      );
    });
  });

  test('every key in the script has an entry in the copy file', () {
    final arb = jsonDecode(
      File('lib/l10n/app_en.arb').readAsStringSync(),
    ) as Map<String, Object?>;

    // The script's keys, with `break` spelled `onBreak` (Dart keeps `break`).
    const scriptKeys = [
      'blockDone',
      'blockDoneChattyTaskTotal',
      'levelUp',
      'levelUpChattyTotalTime',
      'evolution',
      'evolutionChattyTotalTime',
      'taskDone',
      'taskDoneChattyTaskTotal',
      'onBreak',
      'onBreakChattyToday',
      'breakOver',
      'breakOverChattyToday',
      'hatch',
      'hatchChattyFirstBlock',
      'setup',
      'setupChatty',
      'egg',
      'awayNote',
      'countdown',
      'estimate',
      'pickTitle',
      'pickLine',
      'persLabel',
      'persHint',
      'taskTitle',
      'taskLine',
      'permFrame',
      'permDenied',
      'autoNote',
      'clock',
      'stopTitle',
      'stopBody',
      'delTaskTitle',
      'delTask',
      'delTaskNone',
      'delProjTitle',
      'delProj',
      'delProjNone',
      'delProjNoFocus',
      'delTaskLong',
      'lockTask',
      'lockProject',
      'emptyProjectsTitle',
      'emptyProjects',
      'emptyProjectTitle',
      'emptyProject',
      'allDone',
      'doneTask',
      'otherRunning',
      'about',
      'aboutOs',
      'shareDiag',
      'error',
      'customTitle',
      'customFocus',
      'customBreak',
      'customUse',
      'customChip',
      'startAnotherTask',
    ];

    expect(arb.keys, containsAll(scriptKeys));
    for (final key in scriptKeys) {
      expect(arb['@$key'], isNotNull, reason: '$key needs a description');
    }
  });
}

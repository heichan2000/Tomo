import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/l10n/app_localizations.dart';
import 'package:tomo/voice/pet_voice.dart';
import 'package:tomo_core/notifications/notification_schedule.dart';
import 'package:tomo_core/pet/beat.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/voice/pet_moment.dart';

/// Every pet line is held to the approved lines, word for word: the expected
/// text below is copied from
/// https://github.com/heichan2000/Tomo/issues/115#issuecomment-6258694999
/// (each pet in its own character, ADR-0030), with this test's own sample (a
/// 25-minute block on "Write the intro", 3 blocks and 75 minutes so far,
/// level 8, stage 2, a 15-minute first block). The egg's lines are in the
/// plain voice, so nothing names the pet before the hatch; they are copied
/// from https://github.com/heichan2000/Tomo/issues/114.
void main() {
  final l = lookupAppLocalizations(const Locale('en'));
  const task = 'Write the intro';
  const geode = Species.geode;
  const joe = Species.joe;
  const lily = Species.lily;

  String line(PetMoment moment, Species species) =>
      petLine(l, moment: moment, species: species);

  /// Checks one moment: the three pets' lines.
  void row(String name, PetMoment moment, List<String> lines) {
    test(name, () {
      expect([
        line(moment, geode),
        line(moment, joe),
        line(moment, lily),
      ], lines);
    });
  }

  const blockDone = BlockDoneMoment(
    minutes: 25,
    task: task,
    taskBlocks: 3,
    taskMinutes: 75,
  );
  const firstBlock = BlockDoneMoment(
    minutes: 25,
    task: task,
    taskBlocks: 1,
    taskMinutes: 25,
  );
  const levelUp = LevelUpMoment(level: 8, levelBefore: 7, totalMinutes: 425);
  const earlyLevelUp = LevelUpMoment(
    level: 2,
    levelBefore: 1,
    totalMinutes: 55,
  );
  const evolution = EvolutionMoment(stage: 2, totalMinutes: 540);
  const taskDone = TaskDoneMoment(task: task, taskBlocks: 4, taskMinutes: 100);
  const untouchedTask = TaskDoneMoment(
    task: task,
    taskBlocks: 0,
    taskMinutes: 0,
  );
  const onBreak = OnBreakMoment(
    breakMinutes: 5,
    todayBlocks: 3,
    todayMinutes: 75,
  );
  // A break after midnight, with nothing finished yet today.
  const newDayBreak = OnBreakMoment(
    breakMinutes: 5,
    todayBlocks: 0,
    todayMinutes: 0,
  );
  const breakOver = BreakOverMoment(
    breakMinutes: 5,
    todayBlocks: 3,
    todayMinutes: 75,
  );
  const newDayBreakOver = BreakOverMoment(
    breakMinutes: 5,
    todayBlocks: 0,
    todayMinutes: 0,
  );
  const hatch = HatchMoment(minutes: 15, task: task);
  const away = AwayNoteMoment(time: '2:25 PM', minutes: 25);
  const countdown = CountdownMoment(seconds: 10);
  const estimate = EstimateMoment(estimate: 4);

  group('the approved lines, word for word', () {
    row('block done', firstBlock, [
      'Twenty-five minutes. Nice and steady.',
      '25 of 25 minutes. Folded, creased, filed.',
      "You did the whole block! You're getting good at this, aren't you?",
    ]);
    row('block done, on a task with 2 or more blocks', blockDone, [
      'Twenty-five minutes. Nice and steady. Seventy-five on Write the intro '
          'now.',
      '25 of 25 minutes. Block 3 on Write the intro, filed in order.',
      "That's 3 blocks for Write the intro now! You don't give up, do you?",
    ]);
    row('level-up, before a whole hour', earlyLevelUp, [
      'Level two. One more layer, calm and solid.',
      'Level 2! Up from 1. Records updated, neatly.',
      "Level 2! I knew you could do it, didn't I?",
    ]);
    row('level-up, with the total time', levelUp, [
      'Level eight. Seven hours of layers now, each one holding.',
      'Level 8! Up from 7. 425 minutes on file, each in its place.',
      "Level 8! That's 7 hours of focus. You're amazing, aren't you?",
    ]);
    row(
      'evolution, before two whole hours',
      const EvolutionMoment(stage: 2, totalMinutes: 60),
      [
        'I am bigger. Slowly, gently. All of me is still here.',
        'Stage 2 of 4! Refolded. Every crease exactly right.',
        "Look at me, I'm bigger! You did this, didn't you?",
      ],
    );
    row('evolution, with the total time', evolution, [
      'I am bigger. Nine hours, laid down gently. All of me is still here.',
      'Stage 2 of 4! Refolded from 9 hours of focus. Every crease exactly '
          'right.',
      'Look at me! 9 hours of your focus made me bigger. You did this, '
          "didn't you?",
    ]);
    row('task done, never focused on', untouchedTask, [
      'Write the intro is done. A good, quiet feeling. It stays done.',
      'Done: Write the intro! Ticked, filed, put away.',
      "You finished Write the intro! That feels great, doesn't it?",
    ]);
    row('task done, with its focus time', taskDone, [
      'Write the intro is done. One hundred minutes rest in it, and they '
          'stay.',
      'Done: Write the intro! 4 blocks, 100 minutes. Ticked, filed, put '
          'away.',
      'You finished Write the intro, all 4 blocks of it! That feels great, '
          "doesn't it?",
    ]);
    row('break, with nothing finished today', newDayBreak, [
      "It's break time.",
      'Break: 5 minutes. Desk tidied for the next one.',
      "Break time! You earned it, didn't you?",
    ]);
    row('break, with what was finished today', onBreak, [
      "It's break time. Seventy-five minutes today.",
      'Break: 5 minutes. 3 blocks filed today.',
      "Break time, after 3 blocks today! You earned it, didn't you?",
    ]);
    row('break over, with nothing finished today', newDayBreakOver, [
      'The break is whole. Calm, and ready. I am here.',
      'Break done: 5 of 5 minutes. Desk is tidy and ready.',
      "You're back! All rested, aren't you?",
    ]);
    row('break over, with what was finished today', breakOver, [
      'The break is whole. Seventy-five minutes today, and I am here.',
      "Break done: 5 of 5 minutes. 3 blocks on today's list.",
      "You're back, with 3 blocks done today! All rested, aren't you?",
    ]);
    row('the hatch line', hatch, [
      'Hello. Fifteen minutes of Write the intro, and I am made of them.',
      'Hello! 1 block, 15 minutes on Write the intro, 1 me. First entry, '
          'filed!',
      'Oh! You did it! 15 minutes on Write the intro, and here I am. That was '
          "you, wasn't it?",
    ]);
    row('while you were away', away, [
      '2:25 PM: the block is whole, quietly, on its own. Twenty-five '
          'minutes, counted.',
      'Finished at 2:25 PM. 25 of 25 minutes, logged and filed.',
      'Your block finished at 2:25 PM while you were away. All 25 minutes '
          "count, don't they?",
    ]);
    row('countdown line', countdown, [
      'Steady. The next block begins in ten.',
      'Next block in 10. Pencils sharpened.',
      "Your next block starts in 10. You've got this, haven't you?",
    ]);
    row('estimate card fact', estimate, [
      'Every planned block is here. Steady work, all of it.',
      '4 of 4 planned blocks. Exactly to plan. Lovely.',
      "That's all 4 blocks you planned for it. You kept your word, didn't "
          'you?',
    ]);
  });

  group('one of something is said as one', () {
    test('task done in one block', () {
      const oneBlock = TaskDoneMoment(
        task: task,
        taskBlocks: 1,
        taskMinutes: 25,
      );

      expect(
        line(oneBlock, lily),
        'You finished Write the intro in just one block! That feels great, '
        "doesn't it?",
      );
      expect(
        line(oneBlock, joe),
        'Done: Write the intro! 1 block, 25 minutes. Ticked, filed, put away.',
      );
      expect(
        line(oneBlock, geode),
        'Write the intro is done. Twenty-five minutes rest in it, and they '
        'stay.',
      );
    });

    test('the estimate card, when the plan was one block', () {
      const one = EstimateMoment(estimate: 1);

      expect(
        [line(one, geode), line(one, joe), line(one, lily)],
        [
          'Every planned block is here. Steady work, all of it.',
          '1 of 1 planned block. Exactly to plan. Lovely.',
          "That's the one block you planned for it. You kept your word, "
              "didn't you?",
        ],
      );
    });

    test('one hour', () {
      const second = LevelUpMoment(level: 2, levelBefore: 1, totalMinutes: 60);

      expect(
        line(second, geode),
        'Level two. One hour of layers now, each one holding.',
      );
      expect(
        line(second, lily),
        "Level 2! That's 1 hour of focus. You're amazing, aren't you?",
      );
    });

    test('one block today, a one-minute break', () {
      const short = OnBreakMoment(
        breakMinutes: 1,
        todayBlocks: 1,
        todayMinutes: 25,
      );

      expect(
        line(
          const OnBreakMoment(breakMinutes: 1, todayBlocks: 0, todayMinutes: 0),
          joe,
        ),
        'Break: 1 minute. Desk tidied for the next one.',
      );
      expect(line(short, joe), 'Break: 1 minute. 1 block filed today.');
      expect(
        line(short, lily),
        "Break time, after 1 block today! You earned it, didn't you?",
      );
    });
  });

  // The cases the first script had no line for, worded by the user in
  // https://github.com/heichan2000/Tomo/issues/85.
  group('lines added after the script', () {
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

  group('the rules every line keeps', () {
    // Every moment, with and without its fact, with numbers large and small.
    final moments = <PetMoment>[
      blockDone,
      firstBlock,
      const BlockDoneMoment(
        minutes: 120,
        task: task,
        taskBlocks: 12,
        taskMinutes: 1440,
      ),
      levelUp,
      earlyLevelUp,
      const LevelUpMoment(level: 101, levelBefore: 100, totalMinutes: 6000),
      evolution,
      const EvolutionMoment(stage: 4, totalMinutes: 5940),
      taskDone,
      untouchedTask,
      onBreak,
      newDayBreak,
      const OnBreakMoment(breakMinutes: 30, todayBlocks: 9, todayMinutes: 450),
      breakOver,
      newDayBreakOver,
      hatch,
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
      for (final moment in moments)
        line(moment, species).replaceAll(task, 'TASK'),
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

    test('Geode never speaks of the future', () {
      final future = RegExp(r"\b(will|won't|soon|later|tomorrow|going to)\b");
      for (final line in linesOf(geode)) {
        expect(line, isNot(matches(future)), reason: line);
      }
    });

    test('Joe never says "you"', () {
      for (final line in linesOf(joe)) {
        expect(line, isNot(matches(you)), reason: line);
      }
    });

    test('Joe counts in digits', () {
      for (final moment in [blockDone, levelUp, evolution, hatch, onBreak]) {
        expect(line(moment, joe), contains(RegExp(r'\d')));
      }
    });

    test('only Lily says "you", and she does', () {
      expect(linesOf(lily).where((line) => line.contains(you)), isNotEmpty);
    });

    test('no line suggests putting the work off (ADR-0030)', () {
      final putOff = RegExp(
        r'\b(nap|naps|napping|sleep|sleepy|asleep|later|tomorrow|skip)\b',
        caseSensitive: false,
      );
      for (final species in Species.values) {
        for (final line in linesOf(species)) {
          expect(line, isNot(matches(putOff)), reason: line);
        }
      }
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
        'Twenty-five minutes of Write the intro. They settle in, and they '
            'stay.',
        'Write the intro: 25 of 25 minutes, filed.',
        "You gave Write the intro 25 minutes! Every one counted, didn't it?",
      ]);
    });

    test('block done, break begun', () {
      expect(bodies(NotificationKind.blockCompleteBreakBegun), [
        'Twenty-five minutes of Write the intro, counted. The break is here. '
            'Breathe.',
        'Write the intro: 25 of 25 minutes, filed. Break started: 5 minutes.',
        'You gave Write the intro 25 minutes! Your break has begun. You '
            "earned it, didn't you?",
      ]);
    });

    test('break over', () {
      expect(bodies(NotificationKind.breakComplete), [
        'The break is whole. I am here, steady as ever.',
        'Break finished: 5 of 5 minutes. Desk is ready.',
        "Your break is over! Feeling fresh, aren't you?",
      ]);
    });

    test('the first block, before the hatch', () {
      expect(
        bodies(
          NotificationKind.blockComplete,
          beforeHatch: true,
          focusMinutes: 15,
        ),
        // In the plain voice, naming only the egg (#114).
        [
          '15 minutes of Write the intro, counted. Your stone egg is '
              'cracking!',
          '15 minutes of Write the intro, counted. Your paper egg is '
              'cracking!',
          '15 minutes of Write the intro, counted. Your spotted egg is '
              'cracking!',
        ],
      );
    });

    test('a break that ends before the hatch is seen is plain too (#114)', () {
      expect(bodies(NotificationKind.breakComplete, beforeHatch: true), [
        'Your break is over.',
        'Your break is over.',
        'Your break is over.',
      ]);
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

    test('before the hatch the title names the egg (#114)', () {
      expect(
        [
          for (final species in Species.values)
            notificationText(
              l,
              notification(
                NotificationKind.blockComplete,
                species: species,
                beforeHatch: true,
                petName: null,
              ),
            ).title,
        ],
        ['Your stone egg', 'Your paper egg', 'Your spotted egg'],
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
    // The egg gives nothing away before the hatch (#114).
    test('the eggs: their names, hints and line', () {
      List<String> each(String Function(String species) line) => [
        for (final species in Species.values) line(species.name),
      ];

      expect(each(l.eggName), ['Stone egg', 'Paper egg', 'Spotted egg']);
      expect(each(l.eggHint), [
        'Cool, heavy and very still. Something patient is inside.',
        'It rustles, neatly folded at every edge. Something tidy is inside.',
        'It wiggles when you look at it. Something cheerful is inside.',
      ]);
      expect(each((s) => l.egg(l.eggInLine(s))), [
        'Your stone egg hatches when you finish a focus block.',
        'Your paper egg hatches when you finish a focus block.',
        'Your spotted egg hatches when you finish a focus block.',
      ]);
      expect(l.pickTitle, 'Choose your egg');
      expect(
        l.pickLine,
        'Whatever is inside is yours to keep. It hatches when you finish your '
        'first focus block.',
      );
      expect(l.hatchName('Joe'), 'Name your Joe');
    });

    test('no egg line names a species', () {
      final lines = [
        l.pickTitle,
        l.pickLine,
        for (final species in Species.values) ...[
          l.eggName(species.name),
          l.eggHint(species.name),
          l.egg(l.eggInLine(species.name)),
        ],
      ];
      for (final line in lines) {
        expect(line, isNot(matches(RegExp('Geode|Joe|Lily'))), reason: line);
      }
    });

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
      expect(l.customChip(15), 'Custom\n15 min');
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
        l.srEgg(l.eggName('geode')),
        'Stone egg. It hatches when you finish a focus block.',
      );
      expect(l.srClock(19, task), 'About 19 minutes left on Write the intro.');
      expect(l.srClock(1, task), 'About 1 minute left on Write the intro.');
    });

    String run(List<Beat> beats, PetMoment shown, {String? opening}) =>
        runAnnouncement(
          l,
          facts: RunFacts.of(beats, taskTitle: task),
          petName: 'Geode',
          petLine: line(shown, geode),
          opening: opening,
        );

    test('a run: block done', () {
      expect(
        run(const [BlockCredited(minutes: 25, exp: 250)], firstBlock),
        'Block done: 25 minutes on Write the intro. Geode gained 250 EXP. '
        'Geode: Twenty-five minutes. Nice and steady.',
      );
    });

    test('a run: block and level-up', () {
      expect(
        run(const [
          BlockCredited(minutes: 25, exp: 250),
          LevelUp(level: 8),
        ], levelUp),
        'Block done: 25 minutes on Write the intro. Geode gained 250 EXP and '
        'reached level 8. Geode: Level eight. Seven hours of layers now, each '
        'one holding.',
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
        'reached level 10 and grew to stage 2 of 4. Geode: I am bigger. Nine '
        'hours, laid down gently. All of me is still here.',
      );
    });

    test('a run: task done', () {
      expect(
        run(const [TaskCompleted(bonusExp: 100)], untouchedTask),
        'Task done: Write the intro. Geode gained 100 EXP. Geode: Write the '
        'intro is done. A good, quiet feeling. It stays done.',
      );
    });

    test('a run: block done while away', () {
      expect(
        run(
          const [BlockCredited(minutes: 25, exp: 250)],
          firstBlock,
          opening: line(away, geode),
        ),
        '2:25 PM: the block is whole, quietly, on its own. Twenty-five '
        'minutes, counted. Geode gained 250 EXP. Geode: Twenty-five minutes. '
        'Nice and steady.',
      );
    });

    test('a run: the hatch', () {
      expect(
        run(const [
          BlockCredited(minutes: 15, exp: 150),
          Hatch(species: geode),
        ], hatch),
        'Your egg hatched. Geode: Hello. Fifteen minutes of Write the intro, '
        'and I am made of them.',
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
      'blockDoneTaskTotal',
      'levelUp',
      'levelUpTotalTime',
      'evolution',
      'evolutionTotalTime',
      'taskDone',
      'taskDoneTaskTotal',
      'onBreak',
      'onBreakToday',
      'breakOver',
      'breakOverToday',
      'hatch',
      'eggName',
      'eggInLine',
      'eggHint',
      'egg',
      'awayNote',
      'countdown',
      'estimate',
      'pickTitle',
      'pickLine',
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

  test('no Quiet or Chatty entry is left in the copy file (ADR-0030)', () {
    final arb = jsonDecode(
      File('lib/l10n/app_en.arb').readAsStringSync(),
    ) as Map<String, Object?>;

    expect(arb.keys.where((key) => key.contains('Chatty')), isEmpty);
    expect(arb.keys.where((key) => key.startsWith('pers')), isEmpty);
  });
}

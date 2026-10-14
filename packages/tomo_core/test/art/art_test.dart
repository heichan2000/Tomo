// The one art test (spec §9.6, ADR-0020): it fails if any drawing is missing,
// a draft, or doesn't match its fingerprint. It runs inside tool/check, so a
// release can't be built past it.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:tomo_core/art/drawings.dart';
import 'package:tomo_core/art/icons.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/art/sparkle.dart';
import 'package:tomo_core/art/tomo_egg.dart';

String fingerprintOf(List<String> text) =>
    sha256.convert(utf8.encode(text.join('\n'))).toString().substring(0, 16);

/// What is wrong with [drawings]' marks, one line per drawing.
List<String> markProblems(List<Drawing> drawings) => [
  for (final d in drawings)
    switch (d.mark) {
      Draft() => '${d.id} is a draft',
      Approved(:final fingerprint) when fingerprint != fingerprintOf(d.text) =>
        '${d.id} has changed since it was approved: it is now '
            '${fingerprintOf(d.text)}, approved as $fingerprint',
      Approved() => null,
    },
].nonNulls.toList();

/// What is missing or misshapen, one line each.
List<String> shapeProblems() {
  final problems = <String>[];
  void grid(String what, String grid, int w, int h, Set<String> allowed) {
    final rows = gridRows(grid);
    if (rows.length != h || rows.any((r) => r.length != w)) {
      problems.add('$what is not $w×$h');
    }
    final stray = {
      for (final r in rows)
        for (final c in r.split(''))
          if (c != '.' && !allowed.contains(c)) c,
    };
    if (stray.isNotEmpty) problems.add('$what uses ${stray.join()}');
  }

  final names = allSpecies.map((s) => s.name).toList();
  if (names.join(' ') != 'Geode Joe Lily') {
    problems.add('the starters are $names, not Geode, Joe and Lily');
  }
  for (final species in allSpecies) {
    final name = species.name;
    final key = species.colours.keys.toSet();
    grid('$name egg', species.egg.whole, 48, 48, key);
    if (species.egg.cracks.isEmpty) problems.add('$name egg has no cracks');
    for (final (k, crack) in species.egg.cracks.indexed) {
      grid('$name egg crack ${k + 1}', crack, 48, 48, key);
    }
    if (species.stages.length != 4) {
      problems.add('$name has ${species.stages.length} stages, not 4');
    }
    for (final (i, stage) in species.stages.indexed) {
      for (final part in Part.values) {
        final g = stage.parts[part];
        if (g == null) {
          problems.add('$name stage ${i + 1} has no ${part.name}');
        } else {
          grid('$name stage ${i + 1} ${part.name}', g, 48, 48, key);
        }
      }
    }
    for (final shape in EyeShape.values) {
      final eye = species.eyeSheet.faces[shape];
      if (eye == null) problems.add('$name eye sheet has no ${shape.name}');
    }
  }

  for (final name in IconName.values) {
    final icon = icons[name];
    if (icon == null) {
      problems.add('icon ${name.name} is missing');
    } else {
      grid(
        'icon ${name.name}',
        icon.grid,
        IconArt.size,
        IconArt.size,
        IconArt.paints.keys.toSet(),
      );
    }
  }

  if (sparkle.frames.length != 4) {
    problems.add('the sparkle has ${sparkle.frames.length} frames, not 4');
  }
  for (final (k, frame) in sparkle.frames.indexed) {
    final w = 2 * k + 1;
    grid('sparkle frame ${k + 1}', frame, w, w, Sparkle.paints.keys.toSet());
  }

  grid(
    'the Tomo egg',
    tomoEgg.grid,
    TomoEgg.size,
    TomoEgg.size,
    tomoEgg.colours.keys.toSet(),
  );
  return problems;
}

void main() {
  test('every drawing is there, approved, and matches its fingerprint', () {
    final problems = [...shapeProblems(), ...markProblems(allDrawings())];
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('there are 18 pet drawings, 20 icons, a sparkle and the Tomo egg', () {
    final ids = allDrawings().map((d) => d.id).toList();
    final pets = RegExp(r'^(geode|joe|lily)\.');
    expect(ids.where(pets.hasMatch), hasLength(18));
    expect(ids.where((id) => id.startsWith('icon.')), hasLength(20));
    expect(ids, containsAll(['sparkle', 'tomo.egg']));
    expect(ids, hasLength(18 + 20 + 2));
    expect(ids.toSet(), hasLength(ids.length), reason: 'ids are unique');
  });

  group('the test would catch', () {
    final home = icons[IconName.home]!;
    final approved = Drawing(
      'icon.home',
      home.mark,
      iconText(IconName.home, home),
    );

    test('a draft', () {
      final draft = Drawing(approved.id, const Draft(), approved.text);
      expect(markProblems([draft]), ['icon.home is a draft']);
    });

    test('one pixel changed', () {
      final rows = gridRows(home.grid);
      rows[0] = '#${rows[0].substring(1)}';
      final changed = IconArt(mark: home.mark, grid: rows.join('\n'));
      final drawing = Drawing(
        approved.id,
        changed.mark,
        iconText(IconName.home, changed),
      );
      expect(markProblems([approved]), isEmpty);
      expect(markProblems([drawing]).single, contains('has changed'));
    });

    test('one colour changed', () {
      final egg = TomoEgg(
        mark: tomoEgg.mark,
        colours: {...tomoEgg.colours, 'K': 0xFF000000},
        grid: tomoEgg.grid,
      );
      final drawing = Drawing('tomo.egg', egg.mark, tomoEggText(egg));
      expect(markProblems([drawing]).single, contains('has changed'));
    });
  });

  test('the canonical text is the one the review page hashes', () {
    // Pinned from `node tool/art/review_page.mjs`, so the Dart and Node sides
    // can't drift apart unnoticed.
    expect(sparkleText(sparkle).take(6), [
      'tomo-art 1',
      'drawing sparkle',
      'paint # arms',
      'paint o centre',
      'paint x centre',
      'grid frame1',
    ]);
    expect(tomoEggText(tomoEgg).take(7), [
      'tomo-art 1',
      'drawing tomo.egg',
      'colour B #e9dcc3',
      'colour K #24211d',
      'colour S #c4af8c',
      'colour W #f7f0e2',
      'grid whole',
    ]);
  });
}

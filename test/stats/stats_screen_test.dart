import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/stats/stats_screen.dart';
import 'package:tomo/ui/buttons.dart';
import 'package:tomo_core/data/tomo_database.dart';

import '../app/app_harness.dart';
import '../ui/kit_harness.dart';

/// Stats (spec §8.9): four rows counted fresh from the block records as it
/// opens, numbers grouped the phone's way, the time written as Stats writes
/// it, and nothing that could show zero.
void main() {
  Finder levelChip() => find.byWidgetPredicate(
    (widget) =>
        widget is Pressable && (widget.semanticLabel ?? '').startsWith('Level'),
  );

  /// The harness's Geode, hatched with [exp], and one block record per
  /// entry of [blocks]: its minutes and the local day it ended.
  Future<void> history(
    TomoDatabase db, {
    required int exp,
    required List<(int, String)> blocks,
  }) async {
    await db.customStatement(
      "UPDATE pets SET name = 'Pip', exp = $exp, hatched_at = 1",
    );
    for (final (minutes, day) in blocks) {
      await db.customStatement(
        'INSERT INTO block_records (pet_id, started_at, ended_at, minutes, '
        'local_date, utc_offset_minutes, exp_granted, pet_exp_after, '
        'settled_at) VALUES (1, 0, 0, ?, ?, 0, 0, 1, 0)',
        [minutes, day],
      );
    }
  }

  Future<void> openStats(WidgetTester tester, TomoDatabase db) async {
    await petChanged(tester, db);
    await tester.pumpAndSettle();
    await tester.tap(levelChip());
    // The numbers are read from the database on the real clock.
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pumpAndSettle();
    }
  }

  Iterable<StatRow> rows(WidgetTester tester) =>
      tester.widgetList<StatRow>(find.byType(StatRow));

  testTomo('four rows, counted from the block records', (tester) async {
    final db = await pumpTomo(
      tester,
      before: (db) => history(
        db,
        exp: 600 * 1233 + 10,
        blocks: [(25, '2026-10-01'), (1550, '2026-10-01'), (25, '2026-10-02')],
      ),
    );
    await openStats(tester, db);

    expect(find.byType(StatsScreen), findsOneWidget);
    expect(find.words('Stats'), findsOneWidget);
    expect(
      [for (final row in rows(tester)) (row.label, row.value)],
      [
        ('Level', '1,234'),
        ('Time focused', '26 h 40 min'),
        ('Blocks finished', '3'),
        ('Days focused', '2'),
      ],
    );
  });

  testTomo('just hatched: the smallest Stats can be', (tester) async {
    final db = await pumpTomo(
      tester,
      before: (db) => history(db, exp: 150, blocks: [(15, '2026-10-19')]),
    );
    await openStats(tester, db);

    expect(
      [for (final row in rows(tester)) row.value],
      ['1', '15 min', '1', '1'],
    );
  });

  testTomo('at 200% text the rows still fit, and back returns Home', (
    tester,
  ) async {
    final db = await pumpTomo(
      tester,
      textScale: 2,
      before: (db) => history(
        db,
        exp: 600 * 516,
        blocks: [for (var i = 0; i < 40; i++) (754, '2026-09-${10 + i % 20}')],
      ),
    );
    await openStats(tester, db);

    expect(tester.takeException(), isNull);
    expect(rows(tester).map((row) => row.value), [
      '517',
      '502 h 40 min',
      '40',
      '20',
    ]);

    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is PixelIconButton && widget.semanticLabel == 'Back',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(StatsScreen), findsNothing);
  });
}

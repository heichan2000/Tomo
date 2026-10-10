import 'package:test/test.dart';
import 'package:tomo_core/pet/egg_crack.dart';

/// Which of the egg's pictures shows during a running block (spec §7.2): the
/// pictures, whole and then each crack step, share the block equally.
void main() {
  /// The picture shown at each elapsed minute of a block.
  List<int> across(int focusMinutes, int pictures) => [
    for (var minute = 0; minute < focusMinutes; minute++)
      eggPicture(
        pictures: pictures,
        focusMinutes: focusMinutes,
        elapsedMinutes: minute,
      ),
  ];

  test("Geode's four pictures share a 20-minute block, 5 minutes each", () {
    expect(across(20, 4), [
      ...List.filled(5, 0),
      ...List.filled(5, 1),
      ...List.filled(5, 2),
      ...List.filled(5, 3),
    ]);
  });

  test("Joe's six pictures share a 60-minute block, 10 minutes each", () {
    final shown = across(60, 6);

    for (var picture = 0; picture < 6; picture++) {
      expect(shown.where((p) => p == picture), hasLength(10));
    }
  });

  test("Lily's five pictures share a 25-minute block, 5 minutes each", () {
    final shown = across(25, 5);

    for (var picture = 0; picture < 5; picture++) {
      expect(shown.where((p) => p == picture), hasLength(5));
    }
  });

  test('a block starts with the whole egg', () {
    for (final pictures in [4, 5, 6]) {
      expect(
        eggPicture(pictures: pictures, focusMinutes: 25, elapsedMinutes: 0),
        0,
      );
    }
  });

  test('the last share shows the last crack', () {
    expect(eggPicture(pictures: 4, focusMinutes: 25, elapsedMinutes: 24), 3);
    expect(eggPicture(pictures: 6, focusMinutes: 25, elapsedMinutes: 24), 5);
  });

  test('the pictures only ever move forward through a block', () {
    for (final pictures in [4, 5, 6]) {
      for (final focusMinutes in [10, 15, 25, 50, 120]) {
        final shown = across(focusMinutes, pictures);

        expect(shown, [...shown]..sort(), reason: '$pictures, $focusMinutes');
        expect(shown.toSet(), hasLength(pictures));
      }
    }
  });

  test('when a block does not divide evenly, shares differ by a minute at '
      'most', () {
    // 25 minutes over Joe's six pictures: four minutes each, and one five.
    final shown = across(25, 6);
    final sizes = [
      for (var picture = 0; picture < 6; picture++)
        shown.where((p) => p == picture).length,
    ];

    expect(sizes.reduce((a, b) => a + b), 25);
    expect(sizes.every((size) => size == 4 || size == 5), isTrue);
  });

  test('at or past the end it holds the last crack', () {
    expect(eggPicture(pictures: 4, focusMinutes: 25, elapsedMinutes: 25), 3);
    expect(eggPicture(pictures: 4, focusMinutes: 25, elapsedMinutes: 900), 3);
  });

  test('before the start it is the whole egg', () {
    expect(eggPicture(pictures: 4, focusMinutes: 25, elapsedMinutes: -3), 0);
  });
}

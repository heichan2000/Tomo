import 'package:test/test.dart';
import 'package:tomo_core/voice/number_words.dart';

/// Geode spells numbers in words (spec §10.1). The expected words here are
/// the ones in the approved script.
void main() {
  test('the numbers the script itself spells', () {
    expect(numberWords(8), 'eight');
    expect(numberWords(10), 'ten');
    expect(numberWords(15), 'fifteen');
    expect(numberWords(25), 'twenty-five');
    expect(numberWords(75), 'seventy-five');
    expect(numberWords(100), 'one hundred');
    expect(numberWords(7), 'seven');
    expect(numberWords(9), 'nine');
  });

  test('zero to nineteen', () {
    expect(
      [for (var n = 0; n < 20; n++) numberWords(n)],
      [
        'zero',
        'one',
        'two',
        'three',
        'four',
        'five',
        'six',
        'seven',
        'eight',
        'nine',
        'ten',
        'eleven',
        'twelve',
        'thirteen',
        'fourteen',
        'fifteen',
        'sixteen',
        'seventeen',
        'eighteen',
        'nineteen',
      ],
    );
  });

  test('the tens, with a hyphen before the ones', () {
    expect(numberWords(20), 'twenty');
    expect(numberWords(30), 'thirty');
    expect(numberWords(40), 'forty');
    expect(numberWords(50), 'fifty');
    expect(numberWords(60), 'sixty');
    expect(numberWords(70), 'seventy');
    expect(numberWords(80), 'eighty');
    expect(numberWords(90), 'ninety');
    expect(numberWords(21), 'twenty-one');
    expect(numberWords(99), 'ninety-nine');
  });

  test('hundreds', () {
    expect(numberWords(120), 'one hundred twenty');
    expect(numberWords(101), 'one hundred one');
    expect(numberWords(425), 'four hundred twenty-five');
    expect(numberWords(999), 'nine hundred ninety-nine');
  });

  test('thousands and beyond', () {
    expect(numberWords(1000), 'one thousand');
    expect(numberWords(1200), 'one thousand two hundred');
    expect(numberWords(12345), 'twelve thousand three hundred forty-five');
    expect(numberWords(1000000), 'one million');
    expect(
      numberWords(2147483647),
      'two billion one hundred forty-seven million four hundred eighty-three '
      'thousand six hundred forty-seven',
    );
  });

  test('at the start of a sentence, a capital', () {
    expect(numberWordsCapitalized(25), 'Twenty-five');
    expect(numberWordsCapitalized(100), 'One hundred');
    expect(numberWordsCapitalized(7), 'Seven');
  });

  test('no digits, ever', () {
    for (final n in [0, 5, 10, 19, 25, 100, 425, 5940, 2147483647]) {
      expect(numberWords(n), isNot(matches(RegExp(r'\d'))), reason: '$n');
    }
  });
}

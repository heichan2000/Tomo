/// English numbers in words, because Geode never uses digits (spec §10.1).
/// Tomo is English-only, so this is all the number-speaking it needs.
library;

const _small = [
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
];

const _tens = [
  '',
  '',
  'twenty',
  'thirty',
  'forty',
  'fifty',
  'sixty',
  'seventy',
  'eighty',
  'ninety',
];

const _scales = [
  (1000000000, 'billion'),
  (1000000, 'million'),
  (1000, 'thousand'),
];

/// [n] in words, lower case: `25` is "twenty-five", `100` is "one hundred",
/// `425` is "four hundred twenty-five". For zero and above.
String numberWords(int n) {
  assert(n >= 0, 'Tomo has no negative numbers to say.');
  if (n < 20) return _small[n];
  if (n < 100) {
    final ones = n % 10;
    return ones == 0 ? _tens[n ~/ 10] : '${_tens[n ~/ 10]}-${_small[ones]}';
  }
  if (n < 1000) {
    final rest = n % 100;
    final hundreds = '${_small[n ~/ 100]} hundred';
    return rest == 0 ? hundreds : '$hundreds ${numberWords(rest)}';
  }
  for (final (size, name) in _scales) {
    if (n >= size) {
      final rest = n % size;
      final head = '${numberWords(n ~/ size)} $name';
      return rest == 0 ? head : '$head ${numberWords(rest)}';
    }
  }
  throw StateError('unreachable');
}

/// [n] in words with a capital first letter, for the start of a sentence.
String numberWordsCapitalized(int n) {
  final words = numberWords(n);
  return words[0].toUpperCase() + words.substring(1);
}

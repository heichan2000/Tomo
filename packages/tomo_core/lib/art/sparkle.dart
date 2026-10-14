// The reward sparkle (ADR-0019), from Pixel reward effects
// (https://github.com/heichan2000/Tomo/issues/39). Four frames, 70 ms each:
// medium plays 1 2 3 3 2 1, large 1 2 3 4 4 3 2 1, small 1 2 2 1. It opens and
// closes in place and never travels. Text grids are the one real copy
// (ADR-0020); review them on the page built by `node tool/art/review_page.mjs`.

import 'pixel_art.dart';

const sparkle = Sparkle(
  mark: Approved(
    fingerprint: 'cff6eca1feeb378d',
    approvedIn:
        'https://github.com/heichan2000/Tomo/issues/39#issuecomment-5945625543',
  ),
  frames: [
    r'''
#
''',
    r'''
.#.
#o#
.#.
''',
    r'''
..#..
..#..
##o##
..#..
..#..
''',
    r'''
...#...
...#...
.x.#.x.
###o###
.x.#.x.
...#...
...#...
''',
  ],
);

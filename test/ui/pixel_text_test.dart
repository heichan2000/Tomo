import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/ui/sharp_text.dart';
import 'package:tomo/ui/tomo_theme.dart';

import 'kit_harness.dart';

/// Type (spec §9.2): what [PixelText] adds on top of sharp sizes.
void main() {
  /// Dots per font pixel the text found by [finder] was laid out at.
  int dotsPerFontPixel(WidgetTester tester, Finder finder) {
    final text = tester.widget<Text>(
      find.descendant(of: finder, matching: find.byType(Text)),
    );
    return text.style!.fontSize! ~/ 12;
  }

  /// How many lines the text found by [finder] takes. Inside, one unit is
  /// one dot, and a line is 16 font pixels.
  int lines(WidgetTester tester, Finder finder) {
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: finder, matching: find.byType(RichText)),
    );
    return paragraph.size.height ~/ (16 * dotsPerFontPixel(tester, finder));
  }

  testWidgets('body text grows with the phone\'s text setting', (tester) async {
    await pumpKit(tester, const PixelText('Write the intro'), textScale: 2);
    expect(dotsPerFontPixel(tester, find.byType(PixelText)), 8);
  });

  testWidgets('a number stops growing at 130%', (tester) async {
    await pumpKit(
      tester,
      const PixelText.number('480 / 600 EXP'),
      textScale: 2,
    );
    // Body is 4 dots at 2.625×; 130% is 5.2, rounded up to 6.
    expect(dotsPerFontPixel(tester, find.byType(PixelText)), 6);
  });

  testWidgets('the pet\'s name stops growing at 130% too', (tester) async {
    await pumpKit(
      tester,
      const PixelText('Geode', step: TypeStep.petName),
      textScale: 2,
    );
    // Pet name is 8 dots at 2.625×; 130% is 10.4, rounded up to 11.
    expect(dotsPerFontPixel(tester, find.byType(PixelText)), 11);
  });

  testWidgets('a number in a narrow spot steps down to fit on one line', (
    tester,
  ) async {
    const words = '12:45:30';
    await pumpKit(
      tester,
      const SizedBox(
        width: 60,
        child: PixelText.number(words, step: TypeStep.title),
      ),
    );
    final n = dotsPerFontPixel(tester, find.byType(PixelText));
    // Title is 5 dots here; it doesn't fit in 60 pt (157 dots) at that.
    expect(n, lessThan(5));
    expect(
      lineWidthDots(words, n, TextDirection.ltr),
      lessThanOrEqualTo(157.5),
    );
    expect(lineWidthDots(words, n + 1, TextDirection.ltr), greaterThan(157.5));
    expect(lines(tester, find.byType(PixelText)), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a number never wraps, even at 200% in a narrow spot', (
    tester,
  ) async {
    await pumpKit(
      tester,
      const SizedBox(width: 80, child: PixelText.number('1,234 / 1,800 EXP')),
      textScale: 2,
    );
    expect(lines(tester, find.byType(PixelText)), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every centred line starts on a whole dot', (tester) async {
    for (final dpr in screens) {
      for (final width in [201.0, 202.3, 247.7]) {
        await pumpKit(
          tester,
          SizedBox(
            width: width,
            child: const PixelText(
              'Hatches when you finish a focus block. Each line is centred '
              'on its own, odd widths and all.',
              textAlign: TextAlign.center,
            ),
          ),
          dpr: dpr,
        );
        final lines = tester.allRenderObjects
            .whereType<RenderLinesOnWholeDots>()
            .single;
        final canvas = TestRecordingCanvas();
        lines.paint(TestRecordingPaintingContext(canvas), Offset.zero);
        final starts = [
          for (final call in canvas.invocations)
            if (call.invocation.memberName == #drawParagraph)
              call.invocation.positionalArguments[1] as Offset,
        ];
        // Inside, one unit is one dot. Each line is drawn once, moved so
        // that its own start is whole.
        expect(starts.length, greaterThan(1), reason: '$dpr, $width');
        for (final (i, line) in lines.debugLineLefts.indexed) {
          final start = starts[i].dx + line;
          expect(
            start,
            closeTo(start.roundToDouble(), 1e-6),
            reason: 'line $i at $dpr×, $width pt',
          );
        }
      }
    }
  });

  testWidgets('text takes the theme\'s ink unless told otherwise', (
    tester,
  ) async {
    await pumpKit(tester, const PixelText('Ink'));
    final context = tester.element(find.byType(PixelText));
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style!.color, TomoTheme.of(context).ink);
  });
}

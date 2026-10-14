import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/ui/pixel_box.dart';
import 'package:tomo/ui/ui_pixel.dart';

import 'kit_harness.dart';

/// The UI pixel and the boxes of chrome (spec §9.3, ADR-0017).
void main() {
  group('the UI pixel', () {
    test('is one body font pixel: a whole number of dots', () {
      expect(UiPixel(2).dots, 3);
      expect(UiPixel(2.625).dots, 4);
      expect(UiPixel(2.8125).dots, 5);
      expect(UiPixel(3).dots, 5);
      expect(UiPixel(3.75).dots, 6);
    });

    test('a touch target is the fewest whole UI pixels covering 48 pt', () {
      for (final dpr in [2.0, 2.625, 2.8125, 3.0, 3.5, 3.75]) {
        final u = UiPixel(dpr);
        final pixels = u.target / u.pt;
        expect(pixels, closeTo(pixels.roundToDouble(), 1e-9), reason: '$dpr');
        expect(u.target, greaterThanOrEqualTo(48), reason: '$dpr');
        expect(u.target - u.pt, lessThan(48), reason: '$dpr');
      }
    });

    test('snaps a length to whole UI pixels', () {
      final u = UiPixel(2.625); // 4 dots, 1.524 pt
      expect(u.snap(24) / u.pt, 16);
      expect(u.snap(1) / u.pt, 1);
    });
  });

  group('a box on the screen', () {
    test('has both its start and its end on whole dots', () {
      // At 2.625×, 10.3 pt is 27.04 dots and 20.1 pt is 52.76.
      final r = wholeDotRect(
        const Offset(10.3, 0.2),
        const Size(9.8, 9.8),
        2.625,
      );
      expect(r, const Rect.fromLTRB(27, 1, 53, 26));
    });

    test('keeps its size when it starts on a whole dot', () {
      final r = wholeDotRect(
        const Offset(4 / 2.625, 8 / 2.625),
        const Size(40 / 2.625, 20 / 2.625),
        2.625,
      );
      expect(r, const Rect.fromLTRB(4, 8, 44, 28));
    });
  });

  group('a corner', () {
    test('losing one pixel cuts a square of one unit from each corner', () {
      final outline = steppedOutline(const Rect.fromLTWH(0, 0, 10, 6), [1], 2);
      expect(outline, const [
        Offset(0, 2),
        Offset(2, 2),
        Offset(2, 0),
        Offset(8, 0),
        Offset(8, 2),
        Offset(10, 2),
        Offset(10, 4),
        Offset(8, 4),
        Offset(8, 6),
        Offset(2, 6),
        Offset(2, 4),
        Offset(0, 4),
      ]);
    });

    test('rounding in two steps cuts two then one', () {
      final outline = steppedOutline(const Rect.fromLTWH(0, 0, 10, 10), [
        2,
        1,
      ], 1);
      expect(outline.take(5), const [
        Offset(0, 2),
        Offset(1, 2),
        Offset(1, 1),
        Offset(2, 1),
        Offset(2, 0),
      ]);
    });
  });

  testWidgets('a box placed a fraction of a dot off paints on whole dots', (
    tester,
  ) async {
    await pumpKit(
      tester,
      const Padding(
        padding: EdgeInsets.only(left: 10.3, top: 7.7),
        child: PixelBox(
          fill: Color(0xFF3A6470),
          child: SizedBox(width: 30.1, height: 20.2),
        ),
      ),
    );

    final box = tester.renderObject<RenderPixelBox>(find.byType(PixelBox));
    final canvas = TestRecordingCanvas();
    final context = TestRecordingPaintingContext(canvas);
    box.paint(context, box.localToGlobal(Offset.zero));

    final translate = canvas.invocations.firstWhere(
      (i) => i.invocation.memberName == #translate,
    );
    final [dx as double, dy as double] =
        translate.invocation.positionalArguments;
    expect(dx, wholeDots(tester));
    expect(dy, wholeDots(tester));
  });
}

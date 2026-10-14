import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/ui/sharp_text.dart';

/// Dots per font pixel that [size] comes to on a screen of [dpr].
double _dots(double size, double dpr) => size * dpr / 12;

void main() {
  test('body is about a 10 pt x-height, in whole dots', () {
    expect(bodyDots(2), 3);
    expect(bodyDots(2.625), 4);
    expect(bodyDots(2.8125), 5);
    expect(bodyDots(3), 5);
    expect(bodyDots(3.75), 6);
  });

  test('the steps are set from body', () {
    expect([for (final s in TypeStep.values) s.dots(2.625)], [3, 4, 5, 8]);
    expect([for (final s in TypeStep.values) s.dots(3)], [4, 5, 6, 10]);
  });

  test('a step\'s style is a sharp size on the 16-pixel line', () {
    final style = TypeStep.body.style(2.625, const Color(0xFF000000));
    expect(style.fontFamily, arkPixel);
    expect(_dots(style.fontSize!, 2.625), closeTo(4, 1e-9));
    expect(style.fontSize! * style.height! * 2.625, closeTo(64, 1e-9));
  });

  group('the sharp scaler', () {
    const dpr = 2.625;
    final body = sharpFontSize(4, dpr);

    SharpTextScaler at(double factor) =>
        SharpTextScaler(TextScaler.linear(factor), devicePixelRatio: dpr);

    test('leaves a sharp size alone at 100%', () {
      expect(_dots(at(1).scale(body), dpr), closeTo(4, 1e-9));
    });

    test('rounds a size that is not sharp to the nearest at 100%', () {
      // 18 pt is 3.94 dots per font pixel here.
      expect(_dots(at(1).scale(18), dpr), closeTo(4, 1e-9));
      expect(_dots(at(1).scale(16), dpr), closeTo(4, 1e-9)); // 3.5
      expect(_dots(at(1).scale(15), dpr), closeTo(3, 1e-9)); // 3.28
    });

    test('rounds up above 100%, never down', () {
      expect(_dots(at(1.1).scale(body), dpr), closeTo(5, 1e-9)); // 4.4
      expect(_dots(at(1.3).scale(body), dpr), closeTo(6, 1e-9)); // 5.2
      expect(_dots(at(2).scale(body), dpr), closeTo(8, 1e-9)); // exactly 8
    });

    test('rounds to the nearest below 100%, and never below one dot', () {
      expect(_dots(at(0.85).scale(body), dpr), closeTo(3, 1e-9)); // 3.4
      expect(_dots(at(0.1).scale(body), dpr), closeTo(1, 1e-9));
    });

    test('capped stops growing at 130%, then snaps', () {
      final capped = at(2).capped();
      expect(_dots(capped.scale(body), dpr), closeTo(6, 1e-9)); // 5.2 → 6
    });
  });

  testWidgets('SharpText puts a sharp scaler over the phone\'s', (
    tester,
  ) async {
    late TextScaler seen;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          devicePixelRatio: 2.625,
          textScaler: TextScaler.linear(1.5),
        ),
        child: SharpText(
          child: Builder(
            builder: (context) {
              seen = MediaQuery.textScalerOf(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(seen, isA<SharpTextScaler>());
    final sharp = seen as SharpTextScaler;
    expect(sharp.inner, const TextScaler.linear(1.5));
    expect(sharp.devicePixelRatio, 2.625);
  });

  group('PixelText', () {
    Future<Text> pump(
      WidgetTester tester, {
      required double dpr,
      double textScale = 1,
      TypeStep step = TypeStep.body,
    }) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            devicePixelRatio: dpr,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: SharpText(
                child: PixelText(
                  'Hi',
                  step: step,
                  colour: const Color(0xFF000000),
                ),
              ),
            ),
          ),
        ),
      );
      return tester.widget<Text>(find.byType(Text));
    }

    testWidgets('is laid out in dots, a whole number per font pixel', (
      tester,
    ) async {
      final text = await pump(tester, dpr: 2.8125);
      expect(text.style!.fontSize, 60); // 5 dots × 12
      expect(text.textScaler, TextScaler.noScaling);
    });

    testWidgets('takes up its size in dots, divided back into points', (
      tester,
    ) async {
      await pump(tester, dpr: 2.8125);
      // One line of 16 font pixels at 5 dots each.
      expect(tester.getSize(find.byType(PixelText)).height * 2.8125, 80);
    });

    testWidgets('follows the sharp scaler, rounding up above 100%', (
      tester,
    ) async {
      final text = await pump(tester, dpr: 2.8125, textScale: 1.3);
      expect(text.style!.fontSize, 84); // 6.5 → 7 dots
    });

    testWidgets("the pet's name stops growing at 130%", (tester) async {
      final text = await pump(
        tester,
        dpr: 2.8125,
        textScale: 2,
        step: TypeStep.petName,
      );
      expect(text.style!.fontSize, 156); // 10 × 1.3 = 13 dots
    });
  });
}

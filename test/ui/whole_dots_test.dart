import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/ui/whole_dots.dart';

void main() {
  group('dots per pet pixel (ADR-0014)', () {
    int at(double spot, double dpr) =>
        dotsPerPixel(spot: spot, gridSize: 48, devicePixelRatio: dpr);

    test('the largest whole number that fits, rounded down', () {
      expect(at(192, 2.625), 10); // 10.5
      expect(at(168, 2.625), 9); // 9.19
      expect(at(96, 2.625), 5); // 5.25
      expect(at(192, 2.8125), 11); // 11.25
      expect(at(192, 3), 12); // exactly 12
    });

    test('never below two', () {
      expect(at(96, 1), 2);
      expect(at(10, 3), 2);
    });
  });

  testWidgets('a pixel grid is a whole number of dots each way', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 2.625),
        child: Center(
          child: PixelGrid.inSpot(
            spot: 192,
            rows: List.filled(48, 'A' * 48),
            colours: const {'A': Color(0xFF3A6470)},
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(PixelGrid));
    expect(size.width * 2.625, closeTo(480, 1e-9));
    expect(size.height * 2.625, closeTo(480, 1e-9));
  });
}

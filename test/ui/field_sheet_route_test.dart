import 'package:flutter/material.dart' show Material;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/ui/buttons.dart';
import 'package:tomo/ui/motion.dart';
import 'package:tomo/ui/pixel_box.dart';
import 'package:tomo/ui/rows.dart';
import 'package:tomo/ui/sharp_text.dart';
import 'package:tomo/ui/sheet.dart';
import 'package:tomo/ui/text_field.dart';
import 'package:tomo/ui/tomo_theme.dart';
import 'package:tomo/ui/ui_pixel.dart';
import 'package:tomo/ui/whole_dots.dart';

import 'kit_harness.dart';

/// The text field, the sheet and pushed screens (spec §9.3, §9.4, §8.1).
void main() {
  group('a text field', () {
    PixelBox box(WidgetTester tester) => tester.widget<PixelBox>(
      find.descendant(
        of: find.byType(PixelTextField),
        matching: find.byType(PixelBox),
      ),
    );

    testWidgets('has a one-pixel boundary, two of accent while typing', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpKit(
        tester,
        SizedBox(
          width: 300,
          child: PixelTextField(controller: controller, hint: 'Project name'),
        ),
      );
      final colours = TomoTheme.of(tester.element(find.byType(PixelTextField)));
      expect(box(tester).outline, colours.boundary);
      expect(box(tester).outlineWidth, 1);
      expect(find.words('Project name'), findsOneWidget);

      await tester.tap(find.byType(PixelTextField));
      await tester.pump();
      expect(box(tester).outline, colours.accent);
      expect(box(tester).outlineWidth, 2);

      await tester.enterText(find.byType(EditableText), 'Thesis');
      await tester.pump();
      expect(controller.text, 'Thesis');
      expect(find.words('Project name'), findsNothing);
    });

    testWidgets('keeps its text in place when the outline thickens', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Thesis');
      addTearDown(controller.dispose);
      await pumpKit(
        tester,
        SizedBox(width: 300, child: PixelTextField(controller: controller)),
      );
      final before = tester.getTopLeft(find.byType(EditableText));
      final size = tester.getSize(find.byType(PixelTextField));
      await tester.tap(find.byType(PixelTextField));
      await tester.pump();
      expect(tester.getTopLeft(find.byType(EditableText)), before);
      expect(tester.getSize(find.byType(PixelTextField)), size);
    });

    testWidgets('lays its text out in dots, a whole UI pixel caret', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Thesis');
      addTearDown(controller.dispose);
      await pumpKit(
        tester,
        SizedBox(width: 300, child: PixelTextField(controller: controller)),
        dpr: 2.8125,
      );
      expect(
        find.ancestor(
          of: find.byType(EditableText),
          matching: find.byType(InDots),
        ),
        findsOneWidget,
      );
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.style.fontSize, 12.0 * 5);
      expect(editable.cursorWidth, UiPixel(2.8125).dots);
      expect(editable.cursorOpacityAnimates, isFalse);
    });

    testWidgets('wraps long text and grows', (tester) async {
      final controller = TextEditingController(text: 'One line');
      addTearDown(controller.dispose);
      await pumpKit(
        tester,
        SizedBox(width: 200, child: PixelTextField(controller: controller)),
      );
      final short = tester.getSize(find.byType(PixelTextField)).height;
      controller.text =
          'Read the Kowalski paper and write down the questions it leaves';
      await tester.pump();
      expect(
        tester.getSize(find.byType(PixelTextField)).height,
        greaterThan(short),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('a sheet', () {
    Widget opener(WidgetBuilder sheet) => Builder(
      builder: (context) => PixelButton(
        label: 'Open',
        onPressed: () => showPixelSheet<void>(context, sheet),
      ),
    );

    Widget stopSheet(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PixelText('Stop this block?', step: TypeStep.title),
        PixelButton(
          label: 'Keep going',
          wide: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );

    testWidgets('sits at the bottom over the dither, and a tap on the '
        'dither closes it', (tester) async {
      await pumpKit(tester, opener(stopSheet));
      await tester.tap(find.byType(PixelButton));
      await tester.pumpAndSettle();

      expect(find.byType(Dither), findsOneWidget);
      final colours = TomoTheme.of(tester.element(find.byType(Dither)));
      expect(tester.widget<Dither>(find.byType(Dither)).colour, colours.ground);
      final sheet = tester.getRect(
        find
            .ancestor(
              of: find.words('Stop this block?'),
              matching: find.byType(PixelBox),
            )
            .last,
      );
      expect(sheet.bottom, tester.view.physicalSize.height / 2.625);
      expect(sheet.width, tester.view.physicalSize.width / 2.625);

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.words('Stop this block?'), findsNothing);
      expect(find.byType(Dither), findsNothing);
    });

    testWidgets('slides up 24 pt in whole UI pixels, with nothing fading', (
      tester,
    ) async {
      await pumpKit(tester, opener(stopSheet));
      await tester.tap(find.byType(PixelButton));
      await tester.pump();
      final u = UiPixel(2.625);
      final rest = tester.view.physicalSize.height / 2.625;
      var first = true;
      for (var ms = 0; ms <= 280; ms += 20) {
        final bottom = tester
            .getBottomLeft(
              find
                  .ancestor(
                    of: find.words('Stop this block?'),
                    matching: find.byType(PixelBox),
                  )
                  .last,
            )
            .dy;
        final below = (bottom - rest) / u.pt;
        expect(below, closeTo(below.roundToDouble(), 1e-6), reason: '$ms ms');
        expect(below * u.pt, lessThanOrEqualTo(u.snap(Motion.slide) + 1e-9));
        if (first) expect(below, greaterThan(0));
        first = false;
        expect(
          find.ancestor(
            of: find.words('Stop this block?'),
            matching: find.byType(FadeTransition),
          ),
          findsNothing,
        );
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.pumpAndSettle();
    });

    testWidgets('cross-fades under reduced motion, in 150 ms', (tester) async {
      await pumpKit(tester, opener(stopSheet), reduceMotion: true);
      await tester.tap(find.byType(PixelButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      final fades = tester.widgetList<FadeTransition>(
        find.ancestor(
          of: find.words('Stop this block?'),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fades, isNotEmpty);
      expect(fades.first.opacity.value, closeTo(0.5, 0.01));
      await tester.pump(const Duration(milliseconds: 76));
      expect(fades.first.opacity.value, 1);
    });

    testWidgets('scrolls when its content is taller than the screen', (
      tester,
    ) async {
      await pumpKit(
        tester,
        opener(
          (context) => Column(
            children: [
              for (var i = 0; i < 40; i++) PixelRow(title: 'Project $i'),
            ],
          ),
        ),
        textScale: 2,
      );
      await tester.tap(find.byType(PixelButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      // The dither still shows above it.
      final top = tester
          .getTopLeft(
            find
                .ancestor(
                  of: find.words('Project 0'),
                  matching: find.byType(PixelBox),
                )
                .last,
          )
          .dy;
      expect(top, greaterThan(0));
    });
  });

  group('a pushed screen', () {
    Widget pusher({AxisDirection from = AxisDirection.right}) => Builder(
      builder: (context) => PixelButton(
        label: 'Push',
        onPressed: () => Navigator.of(context).push(
          PixelPageRoute<void>(
            from: from,
            builder: (_) => const Material(
              child: SizedBox.expand(child: PixelText('Pushed')),
            ),
          ),
        ),
      ),
    );

    testWidgets('slides 24 pt from the right in whole UI pixels', (
      tester,
    ) async {
      await pumpKit(tester, pusher());
      await tester.tap(find.byType(PixelButton));
      await tester.pump();
      final u = UiPixel(2.625);
      for (var ms = 0; ms < 280; ms += 20) {
        await tester.pump(const Duration(milliseconds: 20));
        final x = tester.getTopLeft(find.byType(SizedBox).last).dx / u.pt;
        expect(x, closeTo(x.roundToDouble(), 1e-6), reason: '$ms ms');
        expect(x * u.pt, lessThanOrEqualTo(u.snap(Motion.slide) + 1e-9));
      }
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(SizedBox).last).dx, 0);
    });

    testWidgets('a takeover comes up from below', (tester) async {
      await pumpKit(tester, pusher(from: AxisDirection.down));
      await tester.tap(find.byType(PixelButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final at = tester.getTopLeft(find.byType(SizedBox).last);
      expect(at.dx, 0);
      expect(at.dy, greaterThan(0));
      await tester.pumpAndSettle();
    });

    testWidgets('cross-fades under reduced motion', (tester) async {
      await pumpKit(tester, pusher(), reduceMotion: true);
      await tester.tap(find.byType(PixelButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(tester.getTopLeft(find.byType(SizedBox).last).dx, 0);
      expect(find.byType(FadeTransition), findsWidgets);
      await tester.pumpAndSettle();
    });
  });
}

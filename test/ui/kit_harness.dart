import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/tomo_look.dart';
import 'package:tomo/l10n/app_localizations.dart';
import 'package:tomo/ui/sharp_text.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/pet/species.dart';

/// The two screens the kit is checked on: the emulator (2.625×) and the test
/// phone (2.8125×), plus a 3× phone.
const screens = [2.625, 2.8125, 3.0];

var _fontLoaded = false;

/// Loads Ark Pixel, so text is measured as it is on a phone.
Future<void> loadArkPixel() async {
  if (_fontLoaded) return;
  await (FontLoader('ArkPixel')..addFont(
        rootBundle.load('assets/fonts/ark-pixel-12px-proportional-latin.ttf'),
      ))
      .load();
  _fontLoaded = true;
}

/// Pumps [child] in the app's own look, on a 1080 × 2400 phone screen of
/// [dpr], at [textScale], in [theme] around [species].
Future<void> pumpKit(
  WidgetTester tester,
  Widget child, {
  double dpr = 2.625,
  double textScale = 1,
  ThemeName theme = ThemeName.light,
  Species? species = Species.geode,
  bool reduceMotion = false,
}) async {
  await loadArkPixel();
  tester.view
    ..devicePixelRatio = dpr
    ..physicalSize = const Size(1080, 2400);
  addTearDown(tester.view.reset);
  lookOverride.value = LookOverride(
    theme: theme,
    pet: (species: species),
    textScale: textScale,
    reduceMotion: reduceMotion,
  );
  addTearDown(() => lookOverride.value = const LookOverride());
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      scrollBehavior: const TomoScrollBehavior(),
      builder: (context, child) => TomoLook(child: child!),
      home: Align(alignment: Alignment.topLeft, child: child),
    ),
  );
}

/// How many screen dots [points] is on the current test screen.
double dotsOf(WidgetTester tester, double points) =>
    points * tester.view.devicePixelRatio;

/// Whether [points] is a whole number of dots on the current screen.
Matcher wholeDots(WidgetTester tester) => predicate<double>((points) {
  final dots = dotsOf(tester, points);
  return (dots - dots.roundToDouble()).abs() < 1e-6;
}, 'a whole number of dots at ${tester.view.devicePixelRatio}×');

/// Finds Tomo's text by its words, however it is aligned: centred text is
/// not a [Text], so `find.text` misses it.
extension FindWords on CommonFinders {
  Finder words(String words) => byWidgetPredicate(
    (widget) => widget is PixelText && widget.words == words,
    description: 'PixelText "$words"',
  );
}

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tomo_core/data/settings.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/pet/species.dart';

import '../ui/sharp_text.dart';
import '../ui/tomo_theme.dart';

/// What the kit gallery shows in place of the phone's and the app's own
/// settings. A builder's tool: release builds never set it.
@immutable
class LookOverride {
  const LookOverride({this.theme, this.pet, this.textScale, this.reduceMotion});

  final ThemeName? theme;

  /// The pet whose accent to show; `(species: null)` is the egg.
  final ({Species? species})? pet;

  /// The phone's text setting, as a factor.
  final double? textScale;

  final bool? reduceMotion;
}

/// Set by the kit gallery; read by [TomoLook].
final lookOverride = ValueNotifier(const LookOverride());

/// Everything every screen sits in: the theme and accent (spec §9.1), sharp
/// text sizes (§9.2), and the ground behind it all. It goes above the
/// navigator, so routes and sheets get it too.
class TomoLook extends StatelessWidget {
  const TomoLook({
    super.key,
    this.appearance = Appearance.system,
    this.species,
    required this.child,
  });

  /// Settings → Appearance.
  final Appearance appearance;

  /// The pet, or null before the hatch.
  final Species? species;

  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: lookOverride,
    builder: (context, kit, _) {
      var media = MediaQuery.of(context);
      if (kit.textScale case final scale?) {
        media = media.copyWith(textScaler: TextScaler.linear(scale));
      }
      if (kit.reduceMotion case final reduce?) {
        media = media.copyWith(disableAnimations: reduce);
      }
      final colours = TomoColours.of(
        kit.theme ?? themeFor(appearance, media.platformBrightness),
        kit.pet == null ? species : kit.pet!.species,
      );
      return MediaQuery(
        data: media,
        child: SharpText(
          child: TomoTheme(
            colours: colours,
            // Plain ink, never underlined: Flutter's fallback for text with
            // no style above it is a loud yellow underline.
            child: DefaultTextStyle(
              style: TextStyle(
                fontFamily: arkPixel,
                color: colours.ink,
                decoration: TextDecoration.none,
              ),
              // The phone's status bar icons, light on the dark theme's
              // black and dark on the light ground.
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: colours.dark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark,
                child: ColoredBox(color: colours.ground, child: child),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Scrolling without the overscroll stretch or glow: the stretch scales the
/// screen and the glow is a soft shape, and neither stays on whole dots.
class TomoScrollBehavior extends ScrollBehavior {
  const TomoScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

import 'package:flutter/widgets.dart';
import 'package:tomo_core/data/settings.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/pet/species.dart';

/// The chrome's colours in one theme, around one pet (spec §9.1, ADR-0015).
/// The values live in `tomo_core`'s [Palette], where their contrast is tested.
@immutable
class TomoColours {
  const TomoColours(this.palette);

  TomoColours.of(ThemeName theme, Species? species)
    : this(Palette.of(theme, species));

  final Palette palette;

  bool get dark => palette.theme == ThemeName.dark;

  Color get ground => Color(palette.ground);
  Color get surface => Color(palette.surface);
  Color get sunken => Color(palette.sunken);
  Color get ink => Color(palette.ink);
  Color get muted => Color(palette.muted);
  Color get boundary => Color(palette.boundary);
  Color get destructive => Color(palette.destructive);
  Color get onDestructive => Color(palette.onDestructive);
  Color get accent => Color(palette.accent);
  Color get onAccent => Color(palette.onAccent);

  /// [fill] while it is held down: one shade toward the ink.
  Color pressed(Color fill) => Color(palette.pressed(fill.toARGB32()));

  @override
  bool operator ==(Object other) =>
      other is TomoColours &&
      other.palette.theme == palette.theme &&
      other.palette.accent == palette.accent;

  @override
  int get hashCode => Object.hash(palette.theme, palette.accent);
}

/// Which theme to show: the phone's, unless Settings → Appearance says
/// otherwise (spec §9.1).
ThemeName themeFor(Appearance appearance, Brightness phone) =>
    switch (appearance) {
      Appearance.light => ThemeName.light,
      Appearance.dark => ThemeName.dark,
      Appearance.system =>
        phone == Brightness.dark ? ThemeName.dark : ThemeName.light,
    };

/// Hands [colours] to every part below it.
class TomoTheme extends InheritedWidget {
  const TomoTheme({super.key, required this.colours, required super.child});

  final TomoColours colours;

  /// The colours in effect at [context]. Light before the hatch when no
  /// [TomoTheme] is above, as in a bare widget test.
  static TomoColours of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TomoTheme>()?.colours ??
      _fallback;

  static final _fallback = TomoColours.of(ThemeName.light, null);

  @override
  bool updateShouldNotify(TomoTheme oldWidget) => oldWidget.colours != colours;
}

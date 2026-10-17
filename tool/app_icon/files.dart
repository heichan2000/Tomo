// Every app icon and splash file, made from the one Tomo egg grid (spec §9.7,
// App icon and splash screen: https://github.com/heichan2000/Tomo/issues/44).
// `dart run tool/app_icon.dart` writes them; test/tool/app_icon_test.dart
// fails if a committed one differs.

import 'dart:convert';

import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/art/tomo_egg.dart';

import 'png.dart';

/// The icon's background and the splash circle: the warm grey Tomo wears
/// before the hatch. It lives here, not in the art (spec §17, C40).
const iconGrey = 0xFF4A443C;

/// The theme grounds behind the splash circle (spec §9.1).
const groundLight = 0xFFF5F1EA;
const groundDark = 0xFF000000;

const _clear = 0x00000000;
const _white = 0xFFFFFFFF;

const _res = 'android/app/src/main/res';
const _assets = 'ios/Runner/Assets.xcassets';

/// Android's density buckets and their screen dots per dp.
const _densities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

/// Every file, by its path from the repo root.
Map<String, List<int>> appIconFiles([TomoEgg egg = tomoEgg]) {
  if (egg.mark is! Approved) {
    throw StateError(
      'The Tomo egg is a draft. Approve it before making icons.',
    );
  }
  final rows = gridRows(egg.grid);

  // Colours for each way the egg is shown; a missing character is left clear.
  final full = egg.colours;
  // One colour: shell and eyes in the tint, the crack cut out (#44).
  final tint = {
    for (final char in egg.colours.keys)
      if (char != 'K') char: _white,
  };

  return {
    for (final MapEntry(key: bucket, value: dots) in _densities.entries) ...{
      // Adaptive icon layers: 108 dp, the grid over the middle 72 dp at 2 dp
      // per pixel. The background layer is the colour `tomo_icon_grey`.
      '$_res/mipmap-$bucket/ic_launcher_foreground.png': encodePng(
        _egg(rows, full, canvas: 54, inset: 9, dots: (2 * dots).round()),
      ),
      '$_res/mipmap-$bucket/ic_launcher_monochrome.png': encodePng(
        _egg(rows, tint, canvas: 54, inset: 9, dots: (2 * dots).round()),
      ),
      // Android 12+'s splash icon: 240 dp, shown inside the system's 160 dp
      // circle of `tomo_icon_grey`. The egg is its own picture at 4 dp per
      // pixel, not the launcher icon scaled.
      '$_res/drawable-$bucket/splash_egg.png': encodePng(
        _egg(rows, full, canvas: 60, inset: 12, dots: (4 * dots).round()),
      ),
      // The notifications' status-bar icon: 24 dp, one colour, the crack cut
      // out. Android paints it in the system's own colour. 24 dp is not a
      // whole number of egg pixels at most densities, so each edge is
      // rounded, as for the iPhone master.
      '$_res/drawable-$bucket/ic_notification.png': encodePng(
        _fitted(rows, tint, size: (24 * dots).round()),
      ),
    },
    '$_res/values/icon_colors.xml': utf8.encode(_androidColours(groundLight)),
    '$_res/values-night/icon_colors.xml': utf8.encode(
      _androidColours(groundDark),
    ),

    // iPhone: one 1024 master per look. Unverified, like every iPhone file.
    '$_assets/AppIcon.appiconset/AppIcon.png': encodePng(
      _master(rows, full, background: iconGrey),
    ),
    '$_assets/AppIcon.appiconset/AppIcon-Dark.png': encodePng(
      _master(rows, full, background: groundDark),
    ),
    '$_assets/AppIcon.appiconset/AppIcon-Tinted.png': encodePng(
      _master(rows, tint, background: groundDark),
    ),
    '$_assets/AppIcon.appiconset/Contents.json': _json({
      'images': [
        _icon('AppIcon.png'),
        _icon('AppIcon-Dark.png', appearance: 'dark'),
        _icon('AppIcon-Tinted.png', appearance: 'tinted'),
      ],
      'info': _xcode,
    }),

    // iPhone launch screen: the same picture as Android's splash, the 160 pt
    // circle drawn in, on the `LaunchBackground` colour.
    for (final scale in [1, 2, 3])
      '$_assets/LaunchImage.imageset/LaunchImage${scale == 1 ? '' : '@${scale}x'}.png':
          encodePng(_launchPicture(rows, full, scale)),
    '$_assets/LaunchImage.imageset/Contents.json': _json({
      'images': [
        for (final scale in [1, 2, 3])
          {
            'filename': 'LaunchImage${scale == 1 ? '' : '@${scale}x'}.png',
            'idiom': 'universal',
            'scale': '${scale}x',
          },
      ],
      'info': _xcode,
    }),
    '$_assets/LaunchBackground.colorset/Contents.json': _json({
      'colors': [_colour(groundLight), _colour(groundDark, appearance: 'dark')],
      'info': _xcode,
    }),
  };
}

/// The egg on a clear square [canvas] egg pixels wide, [inset] egg pixels in
/// from the top left, each egg pixel [dots] screen dots wide.
Picture _egg(
  List<String> rows,
  Map<String, int> colours, {
  required int canvas,
  required int inset,
  required int dots,
}) {
  final picture = Picture(canvas * dots, canvas * dots)..fill(_clear);
  _paint(
    picture,
    rows,
    colours,
    left: inset * dots,
    top: inset * dots,
    edge: (i) => i * dots,
  );
  return picture;
}

/// The egg filling a clear square [size] screen dots wide, each egg pixel's
/// edges rounded to the nearest dot.
Picture _fitted(
  List<String> rows,
  Map<String, int> colours, {
  required int size,
}) {
  final picture = Picture(size, size)..fill(_clear);
  _paint(
    picture,
    rows,
    colours,
    left: 0,
    top: 0,
    edge: (i) => (i * size / TomoEgg.size).round(),
  );
  return picture;
}

/// A 1024 master. 1024 is not a whole number of egg pixels (28.4 each), so
/// each egg pixel's edges are rounded to the nearest whole master pixel: hard
/// edges, no smoothing. A 3× home screen shows it at 180, exactly 5 dots per
/// egg pixel.
Picture _master(
  List<String> rows,
  Map<String, int> colours, {
  required int background,
}) {
  const size = 1024;
  final picture = Picture(size, size)..fill(background);
  _paint(
    picture,
    rows,
    colours,
    left: 0,
    top: 0,
    edge: (i) => (i * size / TomoEgg.size).round(),
  );
  return picture;
}

/// The iPhone launch picture at [scale]: a 160 pt grey circle with the egg
/// centred in it at 4 pt per pixel (144 pt, so 2 egg pixels from each side).
Picture _launchPicture(List<String> rows, Map<String, int> colours, int scale) {
  final dots = 4 * scale;
  final size = 40 * dots;
  final picture = Picture(size, size);
  _circle(picture, iconGrey);
  _paint(
    picture,
    rows,
    colours,
    left: 2 * dots,
    top: 2 * dots,
    edge: (i) => i * dots,
  );
  return picture;
}

/// Paints each egg pixel whose character has a colour as a solid block, from
/// [edge] of its index to [edge] of the next.
void _paint(
  Picture picture,
  List<String> rows,
  Map<String, int> colours, {
  required int left,
  required int top,
  required int Function(int index) edge,
}) {
  for (var y = 0; y < rows.length; y++) {
    for (var x = 0; x < rows[y].length; x++) {
      final colour = colours[rows[y][x]];
      if (colour == null) continue;
      picture.fillRect(
        left + edge(x),
        top + edge(y),
        left + edge(x + 1),
        top + edge(y + 1),
        colour,
      );
    }
  }
}

/// Fills [picture] with a circle touching its sides, in [colour], with a
/// smooth edge (8 × 8 samples per pixel), clear outside.
void _circle(Picture picture, int colour) {
  const samples = 8;
  final radius = picture.width / 2;
  for (var y = 0; y < picture.height; y++) {
    for (var x = 0; x < picture.width; x++) {
      var inside = 0;
      for (var sy = 0; sy < samples; sy++) {
        for (var sx = 0; sx < samples; sx++) {
          final dx = x + (sx + 0.5) / samples - radius;
          final dy = y + (sy + 0.5) / samples - radius;
          if (dx * dx + dy * dy <= radius * radius) inside++;
        }
      }
      final alpha = (inside * 255 / (samples * samples)).round();
      picture.pixels[y * picture.width + x] = alpha == 0
          ? _clear
          : alpha << 24 | colour & 0xFFFFFF;
    }
  }
}

String _androidColours(int ground) {
  final grey = ground == groundLight
      ? '''
    <!-- The icon's background layer and the splash circle (spec §9.7). -->
    <color name="tomo_icon_grey">${_hex(iconGrey)}</color>
'''
      : '';
  return '''
<?xml version="1.0" encoding="utf-8"?>
<!-- Made by `dart run tool/app_icon.dart`. Edit the generator, not this. -->
<resources>
$grey    <!-- The theme's ground, behind the splash circle and the app. -->
    <color name="tomo_ground">${_hex(ground)}</color>
</resources>
''';
}

String _hex(int argb) =>
    '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

const _xcode = {'author': 'xcode', 'version': 1};

List<int> _json(Object value) =>
    utf8.encode('${const JsonEncoder.withIndent('  ').convert(value)}\n');

List<Map<String, String>> _appearance(String value) => [
  {'appearance': 'luminosity', 'value': value},
];

Map<String, Object> _icon(String filename, {String? appearance}) => {
  if (appearance != null) 'appearances': _appearance(appearance),
  'filename': filename,
  'idiom': 'universal',
  'platform': 'ios',
  'size': '1024x1024',
};

Map<String, Object> _colour(int argb, {String? appearance}) {
  String component(int shift) =>
      '0x${(argb >> shift & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase()}';
  return {
    if (appearance != null) 'appearances': _appearance(appearance),
    'color': {
      'color-space': 'srgb',
      'components': {
        'alpha': '1.000',
        'blue': component(0),
        'green': component(8),
        'red': component(16),
      },
    },
    'idiom': 'universal',
  };
}

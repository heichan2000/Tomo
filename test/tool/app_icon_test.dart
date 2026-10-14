import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/art/tomo_egg.dart';

import '../../tool/app_icon/files.dart';
import '../../tool/app_icon/png.dart';

/// The app icon and splash files (spec §9.7). `flutter test` runs these from
/// the repo root.
void main() {
  final files = appIconFiles();
  final rows = gridRows(tomoEgg.grid);
  Picture picture(String path) => decodePng(files[path]!);

  group('the committed files are what the generator writes', () {
    for (final MapEntry(key: path, value: bytes) in files.entries) {
      test(path, () {
        final file = File(path);
        expect(
          file.existsSync(),
          isTrue,
          reason:
              'Run `dart run tool/app_icon.dart` and commit what it writes.',
        );
        if (path.endsWith('.png')) {
          // Pixels, not bytes, so a new zlib in a Flutter upgrade can't fail it.
          _expectSamePicture(
            decodePng(file.readAsBytesSync()),
            decodePng(bytes),
          );
        } else {
          expect(
            file.readAsStringSync(),
            utf8.decode(bytes),
            reason:
                'Run `dart run tool/app_icon.dart` and commit what it writes.',
          );
        }
      });
    }
  });

  test('no icon from the Flutter template is left beside them', () {
    final leftovers =
        [
              ...Directory('android/app/src/main/res')
                  .listSync(recursive: true),
              ...Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset')
                  .listSync(),
            ]
            .whereType<File>()
            .map((f) => f.path.replaceAll(r'\', '/'))
            .where(
              (path) =>
                  path.endsWith('/ic_launcher.png') ||
                  path.contains('Icon-App-'),
            );

    expect(leftovers, isEmpty);
  });

  const dots = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4};
  const res = 'android/app/src/main/res';

  for (final MapEntry(key: bucket, value: scale) in dots.entries) {
    group('Android, $bucket', () {
      final cell = (2 * scale).round();

      test('the foreground is 108 dp, the egg 2 dp per pixel over the middle '
          '72 dp', () {
        final foreground = picture(
          '$res/mipmap-$bucket/ic_launcher_foreground.png',
        );

        expect(foreground.width, (108 * scale).round());
        _expectEgg(
          foreground,
          rows,
          tomoEgg.colours,
          origin: (18 * scale).round(),
          cell: cell,
          elsewhere: 0x00000000,
        );
      });

      test('the monochrome layer is shell and eyes, the crack cut out', () {
        final monochrome = picture(
          '$res/mipmap-$bucket/ic_launcher_monochrome.png',
        );

        _expectEgg(
          monochrome,
          rows,
          {'B': 0xFFFFFFFF, 'S': 0xFFFFFFFF, 'W': 0xFFFFFFFF},
          origin: (18 * scale).round(),
          cell: cell,
          elsewhere: 0x00000000,
        );
      });

      test(
        'the splash egg is 240 dp, the egg 4 dp per pixel in the middle',
        () {
          final splash = picture('$res/drawable-$bucket/splash_egg.png');

          expect(splash.width, (240 * scale).round());
          _expectEgg(
            splash,
            rows,
            tomoEgg.colours,
            origin: (48 * scale).round(),
            cell: 2 * cell,
            elsewhere: 0x00000000,
          );
        },
      );
    });
  }

  group('iPhone', () {
    const icons = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

    test('each master is 1024, opaque, the egg filling the square', () {
      final looks = {
        'AppIcon.png': (iconGrey, tomoEgg.colours),
        'AppIcon-Dark.png': (groundDark, tomoEgg.colours),
        'AppIcon-Tinted.png': (
          groundDark,
          {'B': 0xFFFFFFFF, 'S': 0xFFFFFFFF, 'W': 0xFFFFFFFF},
        ),
      };
      for (final MapEntry(key: name, value: (background, colours))
          in looks.entries) {
        final master = picture('$icons/$name');
        expect((master.width, master.height), (1024, 1024), reason: name);
        // The middle of every egg pixel; edges are rounded to whole pixels.
        for (var y = 0; y < TomoEgg.size; y++) {
          for (var x = 0; x < TomoEgg.size; x++) {
            final at =
                ((y + 0.5) * 1024 / 36).floor() * 1024 +
                ((x + 0.5) * 1024 / 36).floor();
            expect(
              master.pixels[at],
              colours[rows[y][x]] ?? background,
              reason: '$name, egg pixel ($x, $y)',
            );
          }
        }
      }
    });

    test('the launch picture is a 160 pt grey circle, the egg centred at 4 pt '
        'per pixel', () {
      for (final (scale, suffix) in [(1, ''), (2, '@2x'), (3, '@3x')]) {
        final launch = picture(
          'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage$suffix.png',
        );

        expect(launch.width, 160 * scale);
        expect(launch.pixels.first, 0x00000000, reason: 'corner, clear');
        _expectEgg(
          launch,
          rows,
          tomoEgg.colours,
          origin: 8 * scale,
          cell: 4 * scale,
        );
        // Grey just inside the top of the circle, above the egg.
        expect(launch.pixels[4 * scale * launch.width + 80 * scale], iconGrey);
      }
    });
  });

  test('a draft egg makes no icons', () {
    const draft = TomoEgg(mark: Draft(), colours: {}, grid: '');

    expect(() => appIconFiles(draft), throwsStateError);
  });
}

/// Every egg pixel is a solid [cell]-wide block of its colour, starting
/// [origin] dots in from the top left; a character with no colour shows
/// [elsewhere], or isn't looked at when that is null.
void _expectEgg(
  Picture picture,
  List<String> rows,
  Map<String, int> colours, {
  required int origin,
  required int cell,
  int? elsewhere,
}) {
  for (var y = 0; y < rows.length; y++) {
    for (var x = 0; x < rows[y].length; x++) {
      final expected = colours[rows[y][x]] ?? elsewhere;
      if (expected == null) continue;
      for (var dy = 0; dy < cell; dy++) {
        for (var dx = 0; dx < cell; dx++) {
          final px = origin + x * cell + dx;
          final py = origin + y * cell + dy;
          final actual = picture.pixels[py * picture.width + px];
          if (actual != expected) {
            fail(
              'Egg pixel ($x, $y) at dot ($px, $py) is '
              '${actual.toRadixString(16)}, not ${expected.toRadixString(16)}',
            );
          }
        }
      }
    }
  }
}

void _expectSamePicture(Picture actual, Picture expected) {
  expect((actual.width, actual.height), (expected.width, expected.height));
  for (var i = 0; i < expected.pixels.length; i++) {
    if (actual.pixels[i] != expected.pixels[i]) {
      fail(
        'Differs at (${i % expected.width}, ${i ~/ expected.width}). '
        'Run `dart run tool/app_icon.dart` and commit what it writes.',
      );
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:tomo_core/art/pixel_art.dart';

import '../app/routes.dart';
import '../l10n/app_localizations.dart';
import '../ui/back_header.dart';
import '../ui/pixel_icon.dart';
import '../ui/rows.dart';
import '../ui/screen_body.dart';
import '../ui/sharp_text.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';

/// Settings → About → *Licences*: every licence registered with Flutter's
/// [LicenseRegistry], the Ark Pixel font's OFL among them (spec §9.2), one
/// row per package. A row opens that package's licence text.
///
/// Drawn in Tomo's own look rather than Flutter's licence page, so it follows
/// the theme like every other screen.
class LicencesScreen extends StatefulWidget {
  const LicencesScreen({super.key});

  @override
  State<LicencesScreen> createState() => _LicencesScreenState();
}

class _LicencesScreenState extends State<LicencesScreen> {
  late final Future<Map<String, List<LicenseEntry>>> _byPackage = _read();

  static Future<Map<String, List<LicenseEntry>>> _read() async {
    final byPackage = <String, List<LicenseEntry>>{};
    await for (final entry in LicenseRegistry.licenses) {
      for (final package in entry.packages) {
        (byPackage[package] ??= []).add(entry);
      }
    }
    final names = byPackage.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return {for (final name in names) name: byPackage[name]!};
  }

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return ColoredBox(
      color: colours.ground,
      child: FutureBuilder(
        future: _byPackage,
        builder: (context, read) => ScreenBody(
          content: [
            BackHeader(backLabel: words.back, title: words.licences),
            if (read.data case final byPackage?)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: ScreenBody.spaced(context, [
                  for (final MapEntry(key: name, value: entries)
                      in byPackage.entries)
                    PixelRow(
                      title: name,
                      subtitle: words.licenceCount(entries.length),
                      onTap: () => pushInTab(
                        context,
                        (_) => _LicenceText(package: name, entries: entries),
                      ),
                      trailing: [
                        SizedBox.square(
                          dimension: u.target,
                          child: Center(
                            child: PixelIcon(
                              IconName.next,
                              colour: colours.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                ], 3),
              ),
          ],
        ),
      ),
    );
  }
}

/// One package's licences, paragraph by paragraph. Built as it scrolls:
/// some packages carry very long texts.
class _LicenceText extends StatelessWidget {
  const _LicenceText({required this.package, required this.entries});

  final String package;
  final List<LicenseEntry> entries;

  @override
  Widget build(BuildContext context) {
    final words = AppLocalizations.of(context);
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final parts = <Widget>[
      BackHeader(backLabel: words.back, title: package),
      for (final (i, entry) in entries.indexed) ...[
        if (i > 0) SizedBox(height: u(10)),
        for (final paragraph in entry.paragraphs)
          Padding(
            padding: EdgeInsets.only(
              top: u(4),
              left: paragraph.indent == LicenseParagraph.centeredIndent
                  ? 0
                  : u(8) * paragraph.indent,
            ),
            child: PixelText(
              paragraph.text,
              step: TypeStep.caption,
              colour: colours.ink,
              textAlign: paragraph.indent == LicenseParagraph.centeredIndent
                  ? TextAlign.center
                  : TextAlign.start,
            ),
          ),
      ],
    ];
    return ColoredBox(
      color: colours.ground,
      child: SafeArea(
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(u(12), u(6), u(12), u(10)),
          itemCount: parts.length,
          itemBuilder: (context, i) => parts[i],
        ),
      ),
    );
  }
}

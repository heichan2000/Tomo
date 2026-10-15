import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tomo_core/data/settings.dart';

import '../l10n/app_localizations.dart';
import '../ui/pixel_box.dart';
import '../ui/sharp_text.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';
import 'tomo_look.dart';

/// The error block (spec §8.11): a small plain block with the `error` line,
/// which names *Settings > About > Share diagnostics*. Plain voice; no pet.
///
/// It is what a release build shows in place of a part that failed to build
/// ([ErrorWidget.builder]), so it relies on nothing above it: without the
/// app's words or look around it, it brings its own.
class ErrorBlock extends StatelessWidget {
  const ErrorBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final words =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('en'));
    final block = Builder(
      builder: (context) {
        final u = UiPixel.of(context);
        return Center(
          child: Padding(
            padding: EdgeInsets.all(u(4)),
            child: PixelBox(
              fill: TomoTheme.of(context).surface,
              child: Padding(
                padding: EdgeInsets.all(u(7)),
                child: PixelText(words.error),
              ),
            ),
          ),
        );
      },
    );
    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: MediaQuery.maybeOf(context) == null
          ? MediaQuery(
              data: MediaQueryData.fromView(View.of(context)),
              child: SharpText(child: block),
            )
          : block,
    );
  }
}

/// Makes the error block what a release build shows for a part that failed
/// to build. Debug builds keep Flutter's own red report.
void installErrorBlock() {
  if (kReleaseMode) ErrorWidget.builder = (_) => const ErrorBlock();
}

/// What opens when the database could not be (spec §6.2, C19): the error
/// block alone on the ground, in the theme Settings asks for. Nothing else
/// is shown, so nothing can write to a file a newer Tomo left.
class StartFailedApp extends StatelessWidget {
  const StartFailedApp({super.key, required this.appearance});

  final Appearance appearance;

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => AppLocalizations.of(context).appName,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) =>
        TomoLook(appearance: appearance, child: child!),
    home: Builder(
      builder: (context) => Padding(
        padding: EdgeInsets.all(UiPixel.of(context)(8)),
        child: const ErrorBlock(),
      ),
    ),
  );
}

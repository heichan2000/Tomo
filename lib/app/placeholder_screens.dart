import 'package:flutter/widgets.dart';

import '../ui/buttons.dart';
import '../ui/sharp_text.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';

// Stand-ins for the screens their own tickets build, so the shell and the
// start-up routing can be used before them. Each goes when its real screen
// arrives. A builder's tool: their words are not in the copy file.

/// Stands in for Stats, pushed from Home's level chip.
class StatsPlaceholder extends StatelessWidget {
  const StatsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const _Pushed('Stats');
}

/// Stands in for Settings, pushed from Home's gear.
class SettingsPlaceholder extends StatelessWidget {
  const SettingsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const _Pushed('Settings');
}

class _Pushed extends StatelessWidget {
  const _Pushed(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => _Placeholder(
    title: title,
    actions: [('Back', () => Navigator.of(context).pop())],
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title, required this.actions});

  final String title;
  final List<(String, VoidCallback?)> actions;

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return ColoredBox(
      color: colours.ground,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(u(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PixelText(title, step: TypeStep.title),
              SizedBox(height: u(2)),
              PixelText(
                'Placeholder until its own ticket builds it.',
                step: TypeStep.caption,
                colour: colours.muted,
              ),
              for (final (label, onPressed) in actions) ...[
                SizedBox(height: u(6)),
                PixelButton(
                  label: label,
                  kind: ButtonKind.secondary,
                  wide: true,
                  onPressed: onPressed,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

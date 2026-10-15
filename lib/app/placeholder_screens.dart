import 'package:flutter/widgets.dart';

import '../ui/buttons.dart';
import '../ui/sharp_text.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';
import 'routes.dart';

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

class WorkPlaceholder extends StatelessWidget {
  const WorkPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => _Placeholder(
    title: 'Work',
    actions: [
      (
        'A project',
        () => pushInTab(
          context,
          (_) => _Pushed(
            'Project',
            next: (
              'A task',
              (context) => pushInTab(context, (_) => const _Pushed('Task')),
            ),
          ),
        ),
      ),
    ],
  );
}

/// Stands in for the task picker, a sheet. *A task* closes it and opens
/// Focus, as picking a task will.
class TaskPickerPlaceholder extends StatelessWidget {
  const TaskPickerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final u = UiPixel.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PixelText('Task picker', step: TypeStep.title),
        SizedBox(height: u(2)),
        PixelText(
          'Placeholder until its own ticket builds it.',
          step: TypeStep.caption,
          colour: TomoTheme.of(context).muted,
        ),
        SizedBox(height: u(6)),
        PixelButton(
          label: 'A task',
          kind: ButtonKind.secondary,
          wide: true,
          onPressed: () {
            Navigator.of(context).pop();
            openFocus(context);
          },
        ),
      ],
    );
  }
}

/// Stands in for Focus, a takeover over the tab bar.
class FocusPlaceholder extends StatelessWidget {
  const FocusPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => _Placeholder(
    title: 'Focus',
    actions: [('Minimise', () => Navigator.of(context).pop())],
  );
}

class _Pushed extends StatelessWidget {
  const _Pushed(this.title, {this.next});

  final String title;
  final (String, void Function(BuildContext))? next;

  @override
  Widget build(BuildContext context) => _Placeholder(
    title: title,
    actions: [
      ('Back', () => Navigator.of(context).pop()),
      if (next case (final label, final open)) (label, () => open(context)),
    ],
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title, required this.actions});

  final String title;
  final List<(String, VoidCallback)> actions;

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

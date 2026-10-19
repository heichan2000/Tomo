import 'package:flutter/widgets.dart';
import 'package:tomo_core/art/icons.dart';
import 'package:tomo_core/art/pixel_art.dart';
import 'package:tomo_core/tasks/task_status.dart';

import 'sharp_text.dart';
import 'tomo_theme.dart';
import 'whole_dots.dart';

/// One of the 20 shipped icons (spec §9.5), painted from its approved grid at
/// one UI pixel per icon pixel, in one colour chosen here: ink, muted, the
/// accent or on-accent. 12 UI pixels square.
///
/// Decorative: whatever it sits in carries the words.
class PixelIcon extends StatelessWidget {
  const PixelIcon(this.name, {super.key, this.colour, this.scale = 1});

  final IconName name;

  /// Defaults to the theme's ink.
  final Color? colour;

  /// UI pixels per icon pixel: 2 on an empty-state card (spec §8.8).
  final int scale;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: PixelGrid(
      rows: gridRows(icons[name]!.grid),
      colours: {'#': colour ?? TomoTheme.of(context).ink},
      dots: scale * bodyDots(MediaQuery.devicePixelRatioOf(context)),
    ),
  );
}

/// A task's status glyph (spec §9.3): to-do an empty ink ring, doing an
/// accent ring with its left half filled, done filled muted with the check
/// cut out. The status word or the list position goes with it, never colour
/// alone (spec §12).
class StatusGlyph extends StatelessWidget {
  const StatusGlyph(this.status, {super.key});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    return switch (status) {
      TaskStatus.todo => PixelIcon(IconName.todo, colour: colours.ink),
      TaskStatus.doing => PixelIcon(IconName.doing, colour: colours.accent),
      TaskStatus.done => PixelIcon(IconName.done, colour: colours.muted),
    };
  }
}

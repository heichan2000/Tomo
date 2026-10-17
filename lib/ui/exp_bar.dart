import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'pixel_box.dart';
import 'tomo_theme.dart';
import 'ui_pixel.dart';

/// The EXP bar (spec §9.3, ADR-0017): 20 blocks one UI pixel apart, the lit
/// ones in the accent. Each block is 30 EXP, three minutes of focus. It is a
/// reward object, so the reward effects make it spring: the block at [pop]
/// stands one UI pixel taller as it lights, rising above the bar.
///
/// The blocks are as wide as fits, in whole UI pixels, so the bar may end a
/// little short of the width it is given.
class ExpBar extends StatelessWidget {
  const ExpBar({super.key, required this.lit, this.pop, this.semanticLabel});

  static const blocks = 20;

  /// How many blocks are lit, 0 to [blocks].
  final int lit;

  /// The block popping as it lights, if any.
  final int? pop;

  /// What the bar says, for example "480 of 600 EXP".
  final String? semanticLabel;

  /// How wide each block is, in UI pixels, when the bar has [width] UI
  /// pixels. Never under one.
  static int blockWidth(double width) =>
      math.max(1, ((width - (blocks - 1)) / blocks + 1e-9).floor());

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final on = lit.clamp(0, blocks);
    return Semantics(
      label: semanticLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final block = u(blockWidth(constraints.maxWidth / u.pt));
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < blocks; i++) ...[
                if (i > 0) SizedBox(width: u(1)),
                SizedBox(
                  width: block,
                  height: u(6),
                  child: OverflowBox(
                    maxHeight: u(7),
                    alignment: Alignment.bottomCenter,
                    child: PixelBox(
                      fill: i < on ? colours.accent : colours.sunken,
                      cutCorners: false,
                      child: SizedBox(
                        width: block,
                        height: u(i == pop ? 7 : 6),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

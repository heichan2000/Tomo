import 'package:flutter/widgets.dart';

import 'pixel_box.dart';
import 'tomo_theme.dart';
import 'ui_pixel.dart';

/// The thin line under Focus's quiet clock (spec §8.4): 2 UI pixels tall, a
/// sunken track filling from the left in the accent, or in muted ink during
/// a break. It grows in whole UI pixels, never smoothly (spec §9.4).
class ProgressLine extends StatelessWidget {
  const ProgressLine({super.key, required this.progress, this.rest = false});

  /// How far along, from 0 to 1.
  final double progress;

  /// A break: the muted line.
  final bool rest;

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pixels = (constraints.maxWidth / u.pt + 1e-9).floor();
          final lit = (pixels * progress.clamp(0, 1) + 1e-9).floor();
          return PixelBox(
            fill: colours.sunken,
            cutCorners: false,
            child: SizedBox(
              width: u(pixels),
              height: u(2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: lit == 0
                    ? null
                    : PixelBox(
                        fill: rest ? colours.muted : colours.accent,
                        cutCorners: false,
                        child: SizedBox(width: u(lit), height: u(2)),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

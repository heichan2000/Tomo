import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:tomo_core/art/pixel_art.dart';

import 'buttons.dart';
import 'pixel_icon.dart';
import 'sharp_text.dart';
import 'tomo_theme.dart';
import 'ui_pixel.dart';

/// The top of a pushed screen (spec §8.1): back, then the screen's [title]
/// if it has one. The back target reaches into the screen's margin, so its
/// icon lines up with the parts under it.
class BackHeader extends StatelessWidget {
  const BackHeader({super.key, required this.backLabel, this.title});

  /// What a screen reader calls the back button.
  final String backLabel;

  final String? title;

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final title = this.title;
    return LayoutBuilder(
      builder: (context, constraints) => OverflowBox(
        fit: OverflowBoxFit.deferToChild,
        minWidth: constraints.maxWidth + u(12),
        maxWidth: constraints.maxWidth + u(12),
        child: Row(
          children: [
            PixelIconButton(
              icon: PixelIcon(IconName.back, colour: colours.ink),
              semanticLabel: backLabel,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            if (title != null) ...[
              SizedBox(width: u(4)),
              Expanded(
                child: PixelText(title, step: TypeStep.title, header: true),
              ),
              // The title keeps clear of the screen's right margin.
              SizedBox(width: u(6)),
            ],
          ],
        ),
      ),
    );
  }
}

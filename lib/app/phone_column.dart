import 'package:flutter/widgets.dart';

/// The wide-screen column (spec §15.1): on a screen 600 pt wide or more, such
/// as a tablet or an open foldable, the phone layout sits in a centred
/// column [phoneWidth] wide, on the theme's ground (painted by `TomoLook`
/// behind it). Narrower screens get the whole width.
///
/// Both of its edges fall on whole dots, so everything inside starts on one.
class PhoneColumn extends StatelessWidget {
  const PhoneColumn({super.key, required this.child});

  /// From this width the column narrows (spec §15.1).
  static const wideFrom = 600.0;

  /// The column's width: a large phone's.
  static const phoneWidth = 412.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size.width;
    if (screen < wideFrom) return child;

    final dpr = media.devicePixelRatio;
    final width = (phoneWidth * dpr).floorToDouble() / dpr;
    final left = (((screen - width) / 2) * dpr).floorToDouble() / dpr;
    return Padding(
      padding: EdgeInsets.only(left: left),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: MediaQuery(
            // The screens inside see a phone: its width, and no side insets
            // (a cutout at the screen's edge is outside the column).
            data: media.copyWith(
              size: Size(width, media.size.height),
              padding: media.padding.copyWith(left: 0, right: 0),
              viewPadding: media.viewPadding.copyWith(left: 0, right: 0),
              viewInsets: media.viewInsets.copyWith(left: 0, right: 0),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tomo_core/art/pixel_art.dart';

import '../home/home_screen.dart';
import '../l10n/app_localizations.dart';
import '../ui/buttons.dart';
import '../ui/motion.dart';
import '../ui/pixel_box.dart';
import '../ui/pixel_icon.dart';
import '../ui/sharp_text.dart';
import '../ui/tomo_theme.dart';
import '../ui/ui_pixel.dart';
import '../work/work_screen.dart';
import 'routes.dart';
import 'running_banner.dart';

/// The two tabs (spec §8.1).
enum ShellTab { home, work }

/// The frame every tab screen sits in (spec §8.1): Home · Work, each with
/// its own stack of pushed screens, the running-block banner's place, and the
/// tab bar.
///
/// The shell never changes shape. A cold start always opens on Home; the
/// last tab is not remembered. Onboarding and Focus open above it, over the
/// tab bar; sheets too.
class TomoShell extends StatefulWidget {
  const TomoShell({super.key});

  @override
  State<TomoShell> createState() => _TomoShellState();
}

class _TomoShellState extends State<TomoShell> {
  var _tab = ShellTab.home;
  final _stacks = {
    for (final tab in ShellTab.values) tab: GlobalKey<NavigatorState>(),
  };

  void _select(ShellTab tab) {
    if (tab == _tab) {
      // Tapping the tab you are on takes it back to its first screen.
      _stacks[tab]!.currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _tab = tab);
    }
  }

  /// Android back: closes the tab's top screen; on Work's first screen goes
  /// to Home; on Home's first screen leaves the app.
  void _back() {
    final stack = _stacks[_tab]!.currentState;
    if (stack != null && stack.canPop()) {
      stack.pop();
    } else if (_tab != ShellTab.home) {
      setState(() => _tab = ShellTab.home);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _back();
    },
    child: _ShellLayout(
      // The shell makes the room for the keyboard and the phone's own
      // buttons, so the screens inside see neither. Both come off one copy:
      // removing each from the shell's own reading would put the other back.
      content: MediaQuery(
        data: MediaQuery.of(context)
            .removeViewInsets(removeBottom: true)
            .removePadding(removeBottom: true),
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (final tab in ShellTab.values)
              _TabStack(
                key: ValueKey(tab),
                navigatorKey: _stacks[tab]!,
                shown: tab == _tab,
                firstScreen: switch (tab) {
                  ShellTab.home => const HomeScreen(),
                  ShellTab.work => const WorkScreen(),
                },
              ),
          ],
        ),
      ),
      banner: const RunningBannerSlot(),
      tabBar: ShellTabBar(
        selected: _tab,
        onSelect: _select,
        onLongPressHome: kReleaseMode ? null : () => openKitGallery(context),
      ),
    ),
  );
}

/// One tab's own stack. Hidden, it keeps its screens but stops their
/// animations (the pet sleeps, spec §17 C62) and leaves the screen reader.
class _TabStack extends StatelessWidget {
  const _TabStack({
    super.key,
    required this.navigatorKey,
    required this.shown,
    required this.firstScreen,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final bool shown;
  final Widget firstScreen;

  @override
  Widget build(BuildContext context) => Offstage(
    offstage: !shown,
    child: TickerMode(
      enabled: shown,
      child: FocusTraversalGroup(
        child: Navigator(
          key: navigatorKey,
          onGenerateRoute: (settings) => PixelPageRoute<void>(
            settings: settings,
            builder: (_) => firstScreen,
          ),
        ),
      ),
    ),
  );
}

/// Lays the tabs' screens above the banner and the tab bar. When the
/// keyboard is up it covers the banner and the tab bar, and the screen above
/// shrinks to meet it; the shell itself doesn't move.
class _ShellLayout extends StatelessWidget {
  const _ShellLayout({
    required this.content,
    required this.banner,
    required this.tabBar,
  });

  final Widget content;
  final Widget banner;
  final Widget tabBar;

  @override
  Widget build(BuildContext context) => CustomMultiChildLayout(
    delegate: _ShellLayoutDelegate(
      keyboard: MediaQuery.viewInsetsOf(context).bottom,
    ),
    children: [
      LayoutId(id: _Part.content, child: content),
      LayoutId(id: _Part.banner, child: banner),
      LayoutId(id: _Part.tabBar, child: tabBar),
    ],
  );
}

enum _Part { content, banner, tabBar }

class _ShellLayoutDelegate extends MultiChildLayoutDelegate {
  _ShellLayoutDelegate({required this.keyboard});

  final double keyboard;

  @override
  void performLayout(Size size) {
    final width = BoxConstraints.tightFor(width: size.width);
    final tabs = layoutChild(_Part.tabBar, width);
    final banner = layoutChild(_Part.banner, width);
    final bottom = tabs.height + banner.height;
    positionChild(_Part.tabBar, Offset(0, size.height - tabs.height));
    positionChild(_Part.banner, Offset(0, size.height - bottom));
    final contentHeight = math.max(
      0.0,
      size.height - math.max(bottom, keyboard),
    );
    layoutChild(
      _Part.content,
      BoxConstraints.tightFor(width: size.width, height: contentHeight),
    );
    positionChild(_Part.content, Offset.zero);
  }

  @override
  bool shouldRelayout(_ShellLayoutDelegate oldDelegate) =>
      oldDelegate.keyboard != keyboard;
}

/// The tab bar (approved on *Tomo Pixel Screens*): a surface strip of two
/// equal tabs. The chosen tab is sunken, its icon filled in the accent and
/// its word in ink; the other is open, outlined and muted. A tab change is
/// instant (spec §9.4, Feedback).
class ShellTabBar extends StatelessWidget {
  const ShellTabBar({
    super.key,
    required this.selected,
    required this.onSelect,
    this.onLongPressHome,
  });

  final ShellTab selected;
  final ValueChanged<ShellTab> onSelect;

  /// Debug builds only: opens the kit gallery.
  final VoidCallback? onLongPressHome;

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    final words = AppLocalizations.of(context);
    final dpr = u.devicePixelRatio;
    // Under the phone's own buttons or gesture bar, rounded up to whole dots.
    final inset =
        (MediaQuery.viewPaddingOf(context).bottom * dpr).ceilToDouble() / dpr;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: PixelBox(
        fill: colours.surface,
        cutCorners: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(u(8), u(4), u(8), u(4) + inset),
          child: Row(
            children: [
              for (final tab in ShellTab.values) ...[
                if (tab != ShellTab.values.first) SizedBox(width: u(4)),
                Expanded(
                  child: _Tab(
                    label: switch (tab) {
                      ShellTab.home => words.tabHome,
                      ShellTab.work => words.tabWork,
                    },
                    icon: switch ((tab, tab == selected)) {
                      (ShellTab.home, false) => IconName.home,
                      (ShellTab.home, true) => IconName.homeF,
                      (ShellTab.work, false) => IconName.workClip,
                      (ShellTab.work, true) => IconName.workClipF,
                    },
                    selected: tab == selected,
                    onPressed: () => onSelect(tab),
                    onLongPress: tab == ShellTab.home ? onLongPressHome : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
    this.onLongPress,
  });

  final String label;
  final IconName icon;
  final bool selected;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colours = TomoTheme.of(context);
    final u = UiPixel.of(context);
    return Pressable(
      onPressed: onPressed,
      onLongPress: onLongPress,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      builder: (context, pressed, ring) {
        Color? fill = selected ? colours.sunken : null;
        if (pressed) {
          fill = fill == null ? colours.sunken : colours.pressed(fill);
        }
        return PixelBox(
          fill: fill,
          ring: ring ? colours.accent : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: u.target),
            child: Padding(
              padding: EdgeInsets.fromLTRB(u(1), u(3), u(1), u(2)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PixelIcon(
                    icon,
                    colour: selected ? colours.accent : colours.muted,
                  ),
                  SizedBox(height: u(1)),
                  PixelText(
                    label,
                    step: TypeStep.caption,
                    colour: selected ? colours.ink : colours.muted,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

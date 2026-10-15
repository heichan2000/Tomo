import 'package:flutter/widgets.dart';

import '../onboarding/onboarding_screens.dart';
import '../ui/kit_gallery_screen.dart';
import '../ui/motion.dart';
import '../ui/sheet.dart';
import 'placeholder_screens.dart';
import 'shell.dart';
import 'start_up.dart';

/// The app's top-level stack at a cold start (spec §8.1): Onboarding alone
/// until the pet exists; otherwise the shell on Home, with Focus above it
/// when the cycle is live. Opened this way, nothing slides in.
List<Route<void>> firstRoutes(FirstSurface first) => switch (first) {
  FirstSurface.onboarding => [_onboardingRoute()],
  FirstSurface.home => [shellRoute()],
  FirstSurface.focus => [shellRoute(), _focusRoute()],
};

/// The shell, holding Home and Work.
Route<void> shellRoute() => PixelPageRoute<void>(
  settings: const RouteSettings(name: '/'),
  builder: (_) => const TomoShell(),
);

Route<void> _onboardingRoute() => PixelPageRoute<void>(
  settings: const RouteSettings(name: '/onboarding'),
  builder: (_) => const PickPetScreen(),
);

Route<void> _focusRoute() => PixelPageRoute<void>(
  settings: const RouteSettings(name: '/focus'),
  from: AxisDirection.down,
  builder: (_) => const FocusPlaceholder(),
);

/// Onboarding is finished: the shell takes the place of both its screens,
/// on Home.
void finishOnboarding(BuildContext context) => Navigator.of(
  context,
  rootNavigator: true,
).pushAndRemoveUntil(shellRoute(), (_) => false);

/// Opens Focus as a takeover above the shell, over the tab bar (spec §8.1,
/// ADR-0003). Minimise, *Leave*, *Close* and *Stop early* close it again.
void openFocus(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push(_focusRoute());

/// Opens the task picker (spec §8.1), a sheet over the whole app. Picking
/// a task opens Focus on Ready.
void openTaskPicker(BuildContext context) =>
    showPixelSheet<void>(context, (_) => const TaskPickerPlaceholder());

/// Pushes [screen] onto the current tab's own stack (spec §8.1): Project,
/// Task detail, Stats and Settings. The tab bar stays.
void pushInTab(BuildContext context, WidgetBuilder screen) =>
    Navigator.of(context).push(PixelPageRoute<void>(builder: screen));

/// Debug and profile builds: the kit gallery, and through it the pixel check
/// and the Pet gallery (spec §17, C51). Never in release.
void openKitGallery(BuildContext context) => Navigator.of(
  context,
  rootNavigator: true,
).push(PixelPageRoute<void>(builder: (_) => const KitGalleryScreen()));

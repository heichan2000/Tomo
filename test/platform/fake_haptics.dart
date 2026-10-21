import 'package:tomo_core/notifications/haptics.dart';

/// The phone's haptics, kept as a list of what was played.
final class FakeHaptics implements HapticPlayer {
  final played = <Haptic>[];

  @override
  Future<void> play(Haptic haptic) async => played.add(haptic);
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/platform/haptics.dart';
import 'package:tomo_core/notifications/haptics.dart';

/// What each haptic asks of the phone (spec §11.5, ADR-0013). How it feels
/// is checked by hand on the real phone (`docs/manual-checks.md`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const tomo = MethodChannel('tomo/notifications');

  late List<MethodCall> flutter;
  late List<MethodCall> android;

  setUp(() {
    flutter = [];
    android = [];
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      flutter.add(call);
      return null;
    });
    messenger.setMockMethodCallHandler(tomo, (call) async {
      android.add(call);
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    messenger.setMockMethodCallHandler(tomo, null);
    debugDefaultTargetPlatformOverride = null;
  });

  group('on Android', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);

    test(
      'the timer buzz is one real 250 ms buzz, through MainActivity',
      () async {
        await const SystemHaptics().play(Haptic.timerBuzz);

        expect(flutter, isEmpty, reason: 'not the long-press bump');
        expect(android, hasLength(1));
        expect(android.single.method, 'buzz');
        expect(android.single.arguments, {'ms': 250});
      },
    );

    test('a phone that refuses the buzz is not an error', () async {
      messenger.setMockMethodCallHandler(
        tomo,
        (call) async => throw PlatformException(code: 'no-vibrator'),
      );

      await expectLater(
        const SystemHaptics().play(Haptic.timerBuzz),
        completes,
      );
    });

    test('the evolution buzz is one 800 ms buzz, through MainActivity '
        '(C167)', () async {
      messenger.setMockMethodCallHandler(tomo, (call) async {
        android.add(call);
        return true;
      });
      await const SystemHaptics().play(Haptic.evolutionBuzz);

      expect(flutter, isEmpty);
      expect(android.single.method, 'buzz');
      expect(android.single.arguments, {'ms': 800});
    });

    test('an evolution buzz the phone keeps quiet (silent, Do Not Disturb) '
        'is the reward tap instead', () async {
      messenger.setMockMethodCallHandler(tomo, (call) async {
        android.add(call);
        return false;
      });
      await const SystemHaptics().play(Haptic.evolutionBuzz);

      expect(android.single.method, 'buzz');
      expect(flutter.single.arguments, 'HapticFeedbackType.lightImpact');
    });

    test('the reward tap is a light impact', () async {
      await const SystemHaptics().play(Haptic.rewardTap);

      expect(android, isEmpty);
      expect(flutter.single.method, 'HapticFeedback.vibrate');
      expect(flutter.single.arguments, 'HapticFeedbackType.lightImpact');
    });
  });

  group('on iPhone', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);

    test("the evolution buzz is Flutter's vibrate", () async {
      await const SystemHaptics().play(Haptic.evolutionBuzz);

      expect(android, isEmpty);
      expect(flutter.single.method, 'HapticFeedback.vibrate');
      expect(flutter.single.arguments, isNull);
    });

    test("the timer buzz is Flutter's vibrate", () async {
      await const SystemHaptics().play(Haptic.timerBuzz);

      expect(android, isEmpty);
      expect(flutter.single.method, 'HapticFeedback.vibrate');
      expect(flutter.single.arguments, isNull);
    });

    test('the reward tap is a light impact', () async {
      await const SystemHaptics().play(Haptic.rewardTap);

      expect(flutter.single.arguments, 'HapticFeedbackType.lightImpact');
    });
  });

  test('none asks nothing', () async {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      debugDefaultTargetPlatformOverride = platform;
      await const SystemHaptics().play(Haptic.none);
    }

    expect(flutter, isEmpty);
    expect(android, isEmpty);
  });
}

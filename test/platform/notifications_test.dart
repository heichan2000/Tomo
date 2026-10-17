import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/l10n/app_localizations.dart';
import 'package:tomo/platform/notifications.dart';
import 'package:tomo_core/notifications/notification_schedule.dart';

/// How Tomo asks the phone for its notifications (spec §11.3, §11.4,
/// ADR-0008). Whether the phone then delivers them on time is checked by
/// hand (promise 35).
void main() {
  final words = lookupAppLocalizations(const Locale('en'));

  group('alarms', () {
    test('are exact while dozing when the phone allows it', () {
      expect(
        scheduleMode(canBeExact: true),
        AndroidScheduleMode.exactAllowWhileIdle,
      );
    });

    test('are inexact while dozing when it does not', () {
      expect(
        scheduleMode(canBeExact: false),
        AndroidScheduleMode.inexactAllowWhileIdle,
      );
    });

    test('never use the alarm clock', () {
      for (final canBeExact in [true, false]) {
        expect(
          scheduleMode(canBeExact: canBeExact),
          isNot(AndroidScheduleMode.alarmClock),
        );
      }
    });
  });

  group('the two Android channels', () {
    test('are HIGH, with the names and descriptions the spec gives', () {
      final channels = {
        for (final channel in NotificationChannel.values)
          channel: androidChannel(channel, words),
      };
      final block = channels[NotificationChannel.focusBlock]!;
      final rest = channels[NotificationChannel.breakOver]!;

      expect(block.id, 'focus_block_v1');
      expect(block.name, 'Focus block finished');
      expect(
        block.description,
        'When a focus block you started reaches its end.',
      );
      expect(rest.id, 'break_v1');
      expect(rest.name, 'Break finished');
      expect(rest.description, 'When a break reaches its end.');
      for (final channel in channels.values) {
        expect(channel.importance, Importance.high);
        expect(channel.playSound, isTrue, reason: 'the system sound');
        expect(channel.sound, isNull, reason: 'the system sound');
        expect(channel.enableVibration, isTrue);
      }
    });
  });

  group('each notification', () {
    for (final channel in NotificationChannel.values) {
      test('in ${channel.androidId} posts to its channel, private, with no '
          'actions', () {
        final android = notificationDetails(channel, words).android!;

        expect(android.channelId, channel.androidId);
        expect(android.importance, Importance.high);
        expect(android.visibility, NotificationVisibility.private);
        expect(android.actions, isNull);
        expect(android.ongoing, isFalse);
      });

      test(
        'in ${channel.iosCategory} is Time Sensitive, in the one thread',
        () {
          final ios = notificationDetails(channel, words).iOS!;

          expect(ios.interruptionLevel, InterruptionLevel.timeSensitive);
          expect(ios.categoryIdentifier, channel.iosCategory);
          expect(ios.threadIdentifier, 'focusCycle');
          expect(ios.sound, isNull, reason: 'the default sound');
        },
      );
    }
  });

  test('iPhone asks nothing at start, and its categories have no actions', () {
    expect(darwinSettings.requestAlertPermission, isFalse);
    expect(darwinSettings.requestSoundPermission, isFalse);
    expect(darwinSettings.requestBadgePermission, isFalse);
    expect(darwinSettings.requestProvisionalPermission, isFalse);
    expect(darwinSettings.notificationCategories.map((c) => c.identifier), [
      'focusBlock',
      'break',
    ]);
    for (final category in darwinSettings.notificationCategories) {
      expect(category.actions, isEmpty);
    }
  });

  group('the permission', () {
    test('is granted whenever the phone has it on', () {
      for (final asked in [true, false]) {
        for (final canAsk in [true, false]) {
          expect(
            notificationAccess((enabled: true, canAsk: canAsk), asked: asked),
            NotificationAccess.granted,
          );
        }
      }
    });

    test('is undetermined until Tomo has asked and had an answer', () {
      expect(
        notificationAccess((enabled: false, canAsk: true), asked: false),
        NotificationAccess.notDetermined,
      );
      expect(
        notificationAccess((enabled: false, canAsk: true), asked: true),
        NotificationAccess.denied,
      );
    });

    test(
      'on a phone that never asks (Android 12 and older), off is denied',
      () {
        expect(
          notificationAccess((enabled: false, canAsk: false), asked: false),
          NotificationAccess.denied,
        );
      },
    );
  });
}

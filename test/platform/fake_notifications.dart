import 'package:tomo/platform/notifications.dart';
import 'package:tomo_core/notifications/notification_schedule.dart';

/// The phone's pending notifications, kept in memory by slot.
final class FakeScheduler implements NotificationScheduler {
  final pending = <NotificationSlot, TimerNotification>{};
  var clearedDelivered = 0;

  @override
  Future<void> schedule(TimerNotification notification) async =>
      pending[notification.slot] = notification;

  @override
  Future<void> cancel(NotificationSlot slot) async => pending.remove(slot);

  @override
  Future<void> clearDelivered() async => clearedDelivered++;
}

/// A phone whose permission a test sets, and whose dialog answers [answer].
final class FakePermission implements NotificationPermission {
  FakePermission({this.access = (enabled: false, canAsk: true)});

  PhoneAccess access;
  AskOutcome answer = (granted: true, answered: true);
  var asked = 0;
  var settingsOpened = 0;

  @override
  Future<PhoneAccess> read() async => access;

  @override
  Future<AskOutcome> ask() async {
    asked++;
    access = (enabled: answer.granted, canAsk: access.canAsk);
    return answer;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

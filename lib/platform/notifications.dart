import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:tomo_core/notifications/notification_schedule.dart';

import '../l10n/app_localizations.dart';
import '../voice/pet_voice.dart';

/// The phone's notifications through `flutter_local_notifications`
/// (spec §11.1 to §11.3, ADR-0008).
///
/// Only the three timer notifications, each in its fixed slot, scheduled for
/// an absolute instant in UTC. No actions: a tap opens the app and hands back
/// the payload. The package's own boot receiver puts the schedule back after
/// a restart.
final class PhoneNotifications implements NotificationScheduler {
  PhoneNotifications._(this._plugin, this._words);

  /// Readies the package and the two Android channels. [onTap] hears the
  /// payload of a notification tapped while Tomo is running; a tap that
  /// starts Tomo needs nothing, because a cold start already opens Focus on a
  /// live cycle (spec §8.1).
  static Future<PhoneNotifications> open({
    required AppLocalizations words,
    required void Function(String? payload) onTap,
  }) async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(notificationIcon),
        iOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: (response) => onTap(response.payload),
    );
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    for (final channel in NotificationChannel.values) {
      await android?.createNotificationChannel(androidChannel(channel, words));
    }
    return PhoneNotifications._(plugin, words);
  }

  final FlutterLocalNotificationsPlugin _plugin;
  final AppLocalizations _words;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> schedule(TimerNotification notification) async {
    final text = notificationText(_words, notification);
    final canBeExact = await _android?.canScheduleExactNotifications() ?? false;
    await _plugin.zonedSchedule(
      id: notification.slot.id,
      title: text.title,
      body: text.body,
      scheduledDate: tz.TZDateTime.from(notification.fireAt, tz.UTC),
      notificationDetails: notificationDetails(notification.channel, _words),
      androidScheduleMode: scheduleMode(canBeExact: canBeExact),
      payload: notification.payload,
    );
  }

  @override
  Future<void> cancel(NotificationSlot slot) => _plugin.cancel(id: slot.id);

  @override
  Future<void> clearDelivered() async {
    final shown = await _plugin.getActiveNotifications();
    final ours = {for (final slot in NotificationSlot.values) slot.id};
    for (final notification in shown) {
      final id = notification.id;
      if (id != null && ours.contains(id)) await _plugin.cancel(id: id);
    }
  }

  /// What the phone has waiting, for the debug notification check.
  Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();

  /// Whether alarms can be exact right now. Android only; elsewhere null.
  Future<bool?> canBeExact() async => _android?.canScheduleExactNotifications();
}

/// Whether Tomo is on screen, as far as notifications go (spec §11.2).
///
/// Inactive counts as on screen: Tomo is still in view, under the
/// notification shade or beside another app. Before the first frame Tomo is
/// opening, so that counts too.
bool appIsForeground() => switch (WidgetsBinding.instance.lifecycleState) {
  null || AppLifecycleState.resumed || AppLifecycleState.inactive => true,
  AppLifecycleState.hidden ||
  AppLifecycleState.paused ||
  AppLifecycleState.detached => false,
};

/// The small icon in the status bar: the Tomo egg in one colour
/// (`tool/app_icon.dart` writes it).
const notificationIcon = 'ic_notification';

/// Exact while dozing when the phone allows it, otherwise inexact while
/// dozing (spec §11.3). **Never `alarmClock`**: Tomo is a timer, not an
/// alarm clock, and must not put an alarm icon in the status bar.
AndroidScheduleMode scheduleMode({required bool canBeExact}) => canBeExact
    ? AndroidScheduleMode.exactAllowWhileIdle
    : AndroidScheduleMode.inexactAllowWhileIdle;

/// An Android channel as the phone's settings list it: `HIGH`, with the
/// system's own sound and vibration.
AndroidNotificationChannel androidChannel(
  NotificationChannel channel,
  AppLocalizations words,
) {
  final (name, about) = _channelWords(channel, words);
  return AndroidNotificationChannel(
    channel.androidId,
    name,
    description: about,
    importance: Importance.high,
  );
}

/// How one notification looks on each phone.
///
/// Android keeps the lock screen to the phone's own rule: private, so a
/// phone set to hide content hides the task and the minutes. iPhone marks it
/// Time Sensitive, so a Focus mode lets it through.
NotificationDetails notificationDetails(
  NotificationChannel channel,
  AppLocalizations words,
) {
  final (name, about) = _channelWords(channel, words);
  return NotificationDetails(
    android: AndroidNotificationDetails(
      channel.androidId,
      name,
      channelDescription: about,
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.private,
    ),
    iOS: DarwinNotificationDetails(
      presentSound: true,
      categoryIdentifier: channel.iosCategory,
      threadIdentifier: iosThread,
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );
}

/// All three notifications sit in one thread on iPhone.
const iosThread = 'focusCycle';

/// iPhone: the two categories, no actions, and nothing asked at start. The
/// permission is asked at the first block (spec §11.4). Unverified: there is
/// no Mac.
const darwinSettings = DarwinInitializationSettings(
  requestAlertPermission: false,
  requestSoundPermission: false,
  requestBadgePermission: false,
  notificationCategories: [
    DarwinNotificationCategory('focusBlock'),
    DarwinNotificationCategory('break'),
  ],
);

(String, String) _channelWords(
  NotificationChannel channel,
  AppLocalizations words,
) => switch (channel) {
  NotificationChannel.focusBlock => (
    words.channelFocusBlock,
    words.channelFocusBlockAbout,
  ),
  NotificationChannel.breakOver => (
    words.channelBreak,
    words.channelBreakAbout,
  ),
};

/// Whether Tomo may post notifications, as the phone and the device-only
/// file together say (spec §11.4).
enum NotificationAccess {
  /// Never answered: Ready shows the framing line, and Start asks.
  notDetermined,
  granted,

  /// Turned down, or off in the phone's settings. Never asked again by
  /// Tomo; the bell opens the phone's settings.
  denied,
}

/// Where the phone stands, before Tomo's own memory of asking is added.
typedef PhoneAccess = ({bool enabled, bool canAsk});

/// [PhoneAccess] and whether Tomo has asked before, as one answer.
///
/// A phone that never asks (Android 12 and older) is granted or denied by
/// its settings alone; it is never undetermined.
NotificationAccess notificationAccess(
  PhoneAccess phone, {
  required bool asked,
}) => phone.enabled
    ? NotificationAccess.granted
    : !phone.canAsk || asked
    ? NotificationAccess.denied
    : NotificationAccess.notDetermined;

/// What the phone's own permission dialog came back with. [answered] is
/// false when it was dismissed without a choice: then Tomo asks again at the
/// next start.
typedef AskOutcome = ({bool granted, bool answered});

/// The phone's side of the notification permission: reading it, asking, and
/// opening the phone's settings for Tomo.
abstract interface class NotificationPermission {
  Future<PhoneAccess> read();

  /// Shows the phone's dialog and waits until it closes.
  Future<AskOutcome> ask();

  Future<void> openSettings();
}

/// [NotificationPermission] on a real phone. Android 13+ uses
/// `POST_NOTIFICATIONS`; Android 12 and older never ask.
///
/// Android's dialog can be dismissed without an answer. Tomo tells the two
/// apart by Android's own rationale flag, which is true only after a real
/// refusal, read through the `tomo/notifications` channel in `MainActivity`.
final class PhonePermission implements NotificationPermission {
  PhonePermission();

  // The package keeps one instance; this is the one [PhoneNotifications] set up.
  final _plugin = FlutterLocalNotificationsPlugin();
  static const _channel = MethodChannel('tomo/notifications');

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<PhoneAccess> read() async {
    if (_isAndroid) {
      final sdk = await _channel.invokeMethod<int>('sdkInt') ?? 0;
      return (
        enabled: await _android?.areNotificationsEnabled() ?? false,
        canAsk: sdk >= 33,
      );
    }
    final options = await _ios?.checkPermissions();
    return (enabled: options?.isEnabled ?? false, canAsk: true);
  }

  @override
  Future<AskOutcome> ask() async {
    if (_isAndroid) {
      final granted = await _android?.requestNotificationsPermission() ?? false;
      if (granted) return (granted: true, answered: true);
      final refused =
          await _channel.invokeMethod<bool>('shouldShowRationale') ?? false;
      return (granted: false, answered: refused);
    }
    // iPhone's dialog can't be dismissed without an answer.
    final granted =
        await _ios?.requestPermissions(alert: true, sound: true) ?? false;
    return (granted: granted, answered: true);
  }

  @override
  Future<void> openSettings() async {
    if (_isAndroid) {
      await _android?.openAppNotificationSettings();
    } else {
      await _ios?.openAppNotificationSettings();
    }
  }
}

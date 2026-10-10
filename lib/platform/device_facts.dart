import 'dart:io';
import 'dart:ui';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:tomo_core/diagnostics/diagnostic_log.dart';

/// The reproduction context stamped on each diagnostic entry: app version,
/// OS version, device class and locale (ADR-0004). No identifier.
Future<DeviceFacts> readDeviceFacts() async {
  final package = await PackageInfo.fromPlatform();
  final dispatcher = PlatformDispatcher.instance;
  final view = dispatcher.views.firstOrNull;
  return DeviceFacts(
    appVersion: package.version,
    buildNumber: package.buildNumber,
    osVersion: '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    deviceClass: view == null
        ? DeviceClass.phone
        : deviceClassFor(
            view.physicalSize.shortestSide / view.devicePixelRatio,
          ),
    locale: dispatcher.locale.toLanguageTag(),
  );
}

/// A screen whose shorter side is 600 points or more is a tablet, the same
/// line the wide-screen column uses (spec §15.1).
DeviceClass deviceClassFor(double shortestSide) =>
    shortestSide >= 600 ? DeviceClass.tablet : DeviceClass.phone;

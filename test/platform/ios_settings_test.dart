import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tests over the iOS project's files: the settings spec §15.6 fixes.
///
/// These hold the files in place. They do **not** show the project builds:
/// there is no Mac, so nothing here has been through Xcode.
void main() {
  final project = File('ios/Runner.xcodeproj/project.pbxproj')
      .readAsStringSync();
  final info = File('ios/Runner/Info.plist').readAsStringSync();

  test('the oldest iOS is 15.0', () {
    final targets = RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = ([\d.]+);')
        .allMatches(project)
        .map((match) => match.group(1))
        .toSet();

    expect(targets, {'15.0'});
  });

  test('iPhone only', () {
    final families = RegExp(r'TARGETED_DEVICE_FAMILY = ([^;]+);')
        .allMatches(project)
        .map((match) => match.group(1))
        .toSet();

    expect(families, {'1'});
  });

  test('portrait only', () {
    expect(
      RegExp(r'UIInterfaceOrientation\w+').allMatches(info).map((m) => m[0]),
      ['UIInterfaceOrientationPortrait'],
    );
  });

  test('no background modes', () {
    expect(info, isNot(contains('UIBackgroundModes')));
  });

  test('the Time Sensitive capability is asked for', () {
    expect(
      File('ios/Runner/Runner.entitlements').readAsStringSync(),
      contains('com.apple.developer.usernotifications.time-sensitive'),
    );
    expect(
      'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'
          .allMatches(project)
          .length,
      3,
      reason: 'Debug, Release and Profile.',
    );
  });

  test('AppDelegate sets the notification delegate', () {
    expect(
      File('ios/Runner/AppDelegate.swift').readAsStringSync(),
      contains('UNUserNotificationCenter.current().delegate = self'),
    );
  });

  test('no export-compliance question: no encryption of its own', () {
    expect(
      info,
      matches(RegExp(r'<key>ITSAppUsesNonExemptEncryption</key>\s*<false/>')),
    );
  });

  test('the privacy manifest: no tracking, no data, UserDefaults', () {
    final privacy = File('ios/Runner/PrivacyInfo.xcprivacy').readAsStringSync();

    expect(
      privacy,
      matches(RegExp(r'<key>NSPrivacyTracking</key>\s*<false/>')),
    );
    expect(
      privacy,
      matches(RegExp(r'<key>NSPrivacyCollectedDataTypes</key>\s*<array/>')),
    );
    expect(privacy, contains('NSPrivacyAccessedAPICategoryUserDefaults'));
    expect(privacy, contains('CA92.1'));
    expect(
      project,
      contains('PrivacyInfo.xcprivacy in Resources'),
      reason: 'The file must be copied into the app.',
    );
  });

  test('a debug build installs beside the real app as Tomo Dev', () {
    final debug = File('ios/Flutter/Debug.xcconfig').readAsStringSync();
    final release = File('ios/Flutter/Release.xcconfig').readAsStringSync();

    expect(debug, contains('APP_DISPLAY_NAME = Tomo Dev'));
    expect(debug, contains('APP_BUNDLE_ID_SUFFIX = .dev'));
    expect(release, contains('APP_DISPLAY_NAME = Tomo\n'));
    expect(release, contains('APP_BUNDLE_ID_SUFFIX =\n'));
    expect(info, contains(r'<string>$(APP_DISPLAY_NAME)</string>'));
    expect(
      r'PRODUCT_BUNDLE_IDENTIFIER = '
              r'"io.github.heichan2000.tomo$(APP_BUNDLE_ID_SUFFIX)";'
          .allMatches(project)
          .length,
      3,
      reason: 'Debug, Release and Profile.',
    );
  });
}

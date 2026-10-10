import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tests over the Android project's files: the settings spec §15.5, §6.4 and
/// §11.3 fix, so none drifts back to a default unseen. `flutter test` runs
/// them from the repo root.
void main() {
  const main = 'android/app/src/main';
  final manifest = File('$main/AndroidManifest.xml').readAsStringSync();
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();

  group('permissions', () {
    test('exactly the four the spec names', () {
      expect(_permissions(manifest), {
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.USE_EXACT_ALARM',
        'android.permission.SCHEDULE_EXACT_ALARM',
        'android.permission.RECEIVE_BOOT_COMPLETED',
      });
    });

    test('SCHEDULE_EXACT_ALARM stops at Android 12', () {
      expect(
        manifest,
        matches(
          RegExp(
            r'android\.permission\.SCHEDULE_EXACT_ALARM"\s+'
            r'android:maxSdkVersion="32"',
          ),
        ),
      );
    });
  });

  test("the notification package's two receivers are declared", () {
    const package = 'com.dexterous.flutterlocalnotifications';
    expect(manifest, contains('$package.ScheduledNotificationReceiver"'));
    expect(manifest, contains('$package.ScheduledNotificationBootReceiver"'));
    expect(manifest, contains('android.intent.action.BOOT_COMPLETED'));
  });

  group('phone backup (ADR-0028)', () {
    // The database, the two side files SQLite may leave beside it, and the
    // settings file. Nothing else: not the device-only file, not the
    // diagnostic log.
    const backedUp = {
      'file:tomo.sqlite',
      'file:tomo.sqlite-wal',
      'file:tomo.sqlite-journal',
      'sharedpref:FlutterSharedPreferences.xml',
    };

    test('backup is on and points at both rules files', () {
      expect(manifest, contains('android:allowBackup="true"'));
      expect(
        manifest,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );
      expect(
        manifest,
        contains('android:fullBackupContent="@xml/full_backup_content"'),
      );
    });

    test('Android 12+ copies exactly the database and the settings', () {
      final rules = File('$main/res/xml/data_extraction_rules.xml')
          .readAsStringSync();

      expect(_includes(_section(rules, 'cloud-backup')), backedUp);
      expect(_includes(_section(rules, 'device-transfer')), backedUp);
      expect(rules, isNot(contains('<exclude')));
    });

    test('Android 11 and older copy the same', () {
      final rules = File('$main/res/xml/full_backup_content.xml')
          .readAsStringSync();

      expect(_includes(rules), backedUp);
      expect(rules, isNot(contains('<exclude')));
    });
  });

  test('the activity is portrait only', () {
    expect(manifest, contains('android:screenOrientation="portrait"'));
  });

  test('the oldest Android is 8 (API 26)', () {
    expect(gradle, contains('minSdk = 26'));
  });

  test('core library desugaring is on', () {
    expect(gradle, contains('isCoreLibraryDesugaringEnabled = true'));
    expect(gradle, contains('coreLibraryDesugaring('));
  });

  test('the shrinker keeps the notification icon', () {
    expect(
      File('$main/res/raw/keep.xml').readAsStringSync(),
      contains('tools:keep="@drawable/*"'),
    );
  });

  test('a debug build installs beside the real app as Tomo Dev', () {
    expect(gradle, contains('applicationIdSuffix = ".dev"'));
    expect(manifest, contains('android:label="@string/app_name"'));
    expect(
      File('$main/res/values/strings.xml').readAsStringSync(),
      contains('<string name="app_name">Tomo</string>'),
    );
    expect(
      File('android/app/src/debug/res/values/strings.xml').readAsStringSync(),
      contains('<string name="app_name">Tomo Dev</string>'),
    );
  });
}

Set<String> _permissions(String manifest) => {
  for (final match in RegExp(
    r'<uses-permission\s+android:name="([^"]+)"',
  ).allMatches(manifest))
    match.group(1)!,
};

/// The text between `<tag>` and `</tag>`.
String _section(String xml, String tag) {
  final match = RegExp('<$tag>(.*?)</$tag>', dotAll: true).firstMatch(xml);
  if (match == null) fail('No <$tag> section.');
  return match.group(1)!;
}

/// Every `<include>` in [xml], as `domain:path`.
Set<String> _includes(String xml) => {
  for (final match in RegExp(
    r'<include\s+domain="([^"]+)"\s+path="([^"]+)"\s*/>',
  ).allMatches(xml))
    '${match.group(1)}:${match.group(2)}',
};

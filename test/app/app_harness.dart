import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/providers.dart';
import 'package:tomo/app/start_up.dart';
import 'package:tomo/app/tomo_app.dart';
import 'package:tomo/app/tomo_look.dart';
import 'package:tomo_core/data/tomo_database.dart';
import 'package:tomo_core/diagnostics/diagnostic_log.dart';
import 'package:tomo_core/diagnostics/log.dart';
import 'package:tomo_core/look/palette.dart';
import 'package:tomo_core/onboarding/onboarding.dart';
import 'package:tomo_core/pet/personality.dart';
import 'package:tomo_core/pet/species.dart';
import 'package:tomo_core/testing.dart';

import '../ui/kit_harness.dart';

/// Opens the whole app, as `main()` does, on a database in memory: started
/// by [startTomo], so it lands where a cold start would. With [onboarded] the
/// pet already exists.
///
/// Returns the database, closed again when the test ends.
Future<TomoDatabase> pumpTomo(
  WidgetTester tester, {
  bool onboarded = true,
  double dpr = 2.625,
  Size physicalSize = const Size(1080, 2400),
  double textScale = 1,
  ThemeName theme = ThemeName.light,
}) async {
  await loadArkPixel();
  await _closeAll(tester);
  tester.view
    ..devicePixelRatio = dpr
    ..physicalSize = physicalSize;
  addTearDown(tester.view.reset);
  lookOverride.value = LookOverride(theme: theme, textScale: textScale);
  addTearDown(() => lookOverride.value = const LookOverride());

  final log = Log(sinks: const []);
  final db = openTestDatabase(log: log);
  final started = await tester.runAsync(() async {
    if (onboarded) {
      await Onboarding(db, log: log).complete(
        species: Species.geode,
        personality: Personality.quiet,
        defaultProjectName: 'Things',
      );
    }
    return startTomo(
      database: db,
      keyValues: MemoryKeyValueStore(),
      deviceFile: MemoryDeviceFileStorage(),
      log: log,
      diagnostics: DiagnosticLog(
        MemoryDiagnosticLogStorage(),
        facts: () async => const DeviceFacts(
          appVersion: '1.0.0',
          buildNumber: '1',
          osVersion: 'android 16',
          deviceClass: DeviceClass.phone,
          locale: 'en-US',
        ),
      ),
    );
  });
  final ready = started! as Started;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...ready.overrides,
        speciesChangesProvider.overrideWithValue(const Stream.empty()),
      ],
      child: TomoApp(first: ready.first),
    ),
  );
  await tester.pumpAndSettle();
  _open.add(db);
  return db;
}

final _open = <TomoDatabase>[];

/// A widget test of the whole app. When [body] ends, the app is taken down
/// and its database closed, inside the test.
///
/// The database's work runs on the real clock ([WidgetTester.runAsync]): its
/// watched queries never finish on a widget test's pretend one. So the pet's
/// species is handed to the app at start-up and not watched afterwards.
void testTomo(String description, WidgetTesterCallback body) =>
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        await _closeAll(tester);
      }
    });

/// Takes down the app [pumpTomo] opened and closes its database.
Future<void> _closeAll(WidgetTester tester) async {
  if (_open.isEmpty) return;
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  for (final db in _open) {
    await tester.runAsync(db.close);
  }
  _open.clear();
  await tester.pump();
}


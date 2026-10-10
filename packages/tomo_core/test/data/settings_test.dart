import 'package:test/test.dart';
import 'package:tomo_core/data/settings.dart';
import 'package:tomo_core/testing.dart';

/// The key-value store (spec §6.3): six keys, and every read falls back to
/// its default, so a missing or unrecognised value is never an error.
void main() {
  late MemoryKeyValueStore store;
  late Settings settings;

  setUp(() {
    store = MemoryKeyValueStore();
    settings = Settings(store);
  });

  test('with nothing stored, every setting reads its default', () async {
    expect(await settings.appearance(), Appearance.system);
    expect(await settings.autoStart(), isFalse);
    expect(await settings.calmPet(), isFalse);
    expect(await settings.lastFocusMinutes(), 15);
    expect(await settings.lastBreakMinutes(), 5);
    expect(await settings.lastProjectId(), isNull);
  });

  test('what is set is what is read back', () async {
    await settings.setAppearance(Appearance.dark);
    await settings.setAutoStart(true);
    await settings.setCalmPet(true);
    await settings.setLastLengths(focusMinutes: 50, breakMinutes: 10);
    await settings.setLastProjectId(7);

    expect(await settings.appearance(), Appearance.dark);
    expect(await settings.autoStart(), isTrue);
    expect(await settings.calmPet(), isTrue);
    expect(await settings.lastFocusMinutes(), 50);
    expect(await settings.lastBreakMinutes(), 10);
    expect(await settings.lastProjectId(), 7);
  });

  test('the six keys are stored under the names the spec gives', () async {
    await settings.setAppearance(Appearance.light);
    await settings.setAutoStart(true);
    await settings.setCalmPet(true);
    await settings.setLastLengths(focusMinutes: 25, breakMinutes: 5);
    await settings.setLastProjectId(3);

    expect(store.values, {
      'appearance': 'light',
      'autoStart': true,
      'calmPet': true,
      'lastFocusMinutes': 25,
      'lastBreakMinutes': 5,
      'lastProjectId': 3,
    });
  });

  test('forgetting the last project leaves the key absent', () async {
    await settings.setLastProjectId(3);
    await settings.setLastProjectId(null);

    expect(await settings.lastProjectId(), isNull);
    expect(store.values, isNot(contains('lastProjectId')));
  });

  group('a value this app does not recognise reads as the default', () {
    test('an appearance from some other version', () async {
      store.values['appearance'] = 'sepia';

      expect(await settings.appearance(), Appearance.system);
    });

    test('a value of the wrong type', () async {
      store.values.addAll({
        'appearance': 3,
        'autoStart': 'yes',
        'calmPet': 1,
        'lastFocusMinutes': '25',
        'lastBreakMinutes': true,
        'lastProjectId': 'seven',
      });

      expect(await settings.appearance(), Appearance.system);
      expect(await settings.autoStart(), isFalse);
      expect(await settings.calmPet(), isFalse);
      expect(await settings.lastFocusMinutes(), 15);
      expect(await settings.lastBreakMinutes(), 5);
      expect(await settings.lastProjectId(), isNull);
    });

    test('a focus length outside 10 to 120 minutes', () async {
      store.values['lastFocusMinutes'] = 9;
      expect(await settings.lastFocusMinutes(), 15);

      store.values['lastFocusMinutes'] = 121;
      expect(await settings.lastFocusMinutes(), 15);

      store.values['lastFocusMinutes'] = 120;
      expect(await settings.lastFocusMinutes(), 120);
    });

    test('a break length outside 1 to 30 minutes', () async {
      store.values['lastBreakMinutes'] = 0;
      expect(await settings.lastBreakMinutes(), 5);

      store.values['lastBreakMinutes'] = 31;
      expect(await settings.lastBreakMinutes(), 5);

      store.values['lastBreakMinutes'] = 30;
      expect(await settings.lastBreakMinutes(), 30);
    });
  });
}

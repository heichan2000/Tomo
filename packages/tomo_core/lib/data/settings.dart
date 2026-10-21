/// Where the six settings are kept. The app implements this with
/// `shared_preferences`; tests use `MemoryKeyValueStore`.
///
/// A value is a `String`, a `bool` or an `int`.
abstract interface class KeyValueStore {
  /// The value under [key], or null when there is none.
  Future<Object?> read(String key);
  Future<void> write(String key, Object value);
  Future<void> remove(String key);
}

/// Which theme the app wears.
enum Appearance { system, light, dark }

/// The six settings of spec §6.3.
///
/// **Every read falls back to its default.** A key that is missing, of the
/// wrong type, or holding a value this version does not know reads as the
/// default, never as an error; so this store needs no migrations.
final class Settings {
  Settings(this._store);

  final KeyValueStore _store;

  static const defaultFocusMinutes = 25;
  static const defaultBreakMinutes = 5;

  Future<Appearance> appearance() async {
    final stored = await _store.read('appearance');
    return Appearance.values.asNameMap()[stored] ?? Appearance.system;
  }

  Future<void> setAppearance(Appearance value) =>
      _store.write('appearance', value.name);

  /// Whether a break starts by itself when a block ends.
  Future<bool> autoStart() => _readBool('autoStart');
  Future<void> setAutoStart(bool value) => _store.write('autoStart', value);

  Future<bool> calmPet() => _readBool('calmPet');
  Future<void> setCalmPet(bool value) => _store.write('calmPet', value);

  /// The focus length last chosen on Ready: 10 to 120 minutes, at first 25.
  Future<int> lastFocusMinutes() => _readIntWithin(
    'lastFocusMinutes',
    min: 10,
    max: 120,
    fallback: defaultFocusMinutes,
  );

  /// The break length last chosen on Ready: 1 to 30 minutes, at first 5.
  Future<int> lastBreakMinutes() => _readIntWithin(
    'lastBreakMinutes',
    min: 1,
    max: 30,
    fallback: defaultBreakMinutes,
  );

  /// Remembers the pair chosen on Ready (spec §4.7).
  Future<void> setLastLengths({
    required int focusMinutes,
    required int breakMinutes,
  }) async {
    await _store.write('lastFocusMinutes', focusMinutes);
    await _store.write('lastBreakMinutes', breakMinutes);
  }

  /// The last-used project (spec §6.3): where the task picker's *New task*
  /// goes. Set when a block starts, to its task's project, and when *New
  /// task* adds a task. Null means "the most recently active one".
  Future<int?> lastProjectId() async {
    final stored = await _store.read('lastProjectId');
    return stored is int ? stored : null;
  }

  Future<void> setLastProjectId(int? value) => value == null
      ? _store.remove('lastProjectId')
      : _store.write('lastProjectId', value);

  Future<bool> _readBool(String key) async {
    final stored = await _store.read(key);
    return stored is bool && stored;
  }

  Future<int> _readIntWithin(
    String key, {
    required int min,
    required int max,
    required int fallback,
  }) async {
    final stored = await _store.read(key);
    return stored is int && stored >= min && stored <= max ? stored : fallback;
  }
}

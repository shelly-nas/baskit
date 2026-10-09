import 'package:shared_preferences/shared_preferences.dart';

/// Minimal string key-value storage, so local data sources can be tested
/// without platform channels.
abstract class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Device storage: localStorage on web, NSUserDefaults on iOS and
/// SharedPreferences on Android.
class SharedPreferencesStore implements KeyValueStore {
  final SharedPreferencesAsync _prefs;

  SharedPreferencesStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  @override
  Future<String?> read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> delete(String key) => _prefs.remove(key);
}

/// Volatile storage for tests.
class InMemoryStore implements KeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

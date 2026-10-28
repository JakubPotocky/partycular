import 'package:shared_preferences/shared_preferences.dart';

/// A cached copy of the last successful events response.
class CachedEvents {
  const CachedEvents(this.json, this.savedAt);

  final String json;
  final DateTime savedAt;
}

/// Keeps the last events response on the device so the map still works
/// offline or while the server is unreachable.
class EventsCache {
  EventsCache(this._prefs);

  static const _bodyKey = 'events.cache.body';
  static const _savedAtKey = 'events.cache.savedAt';

  final SharedPreferencesWithCache _prefs;

  CachedEvents? read() {
    final json = _prefs.getString(_bodyKey);
    final savedAt = DateTime.tryParse(_prefs.getString(_savedAtKey) ?? '');
    if (json == null || savedAt == null) return null;
    return CachedEvents(json, savedAt);
  }

  Future<void> write(String json, DateTime savedAt) async {
    await _prefs.setString(_bodyKey, json);
    await _prefs.setString(_savedAtKey, savedAt.toUtc().toIso8601String());
  }

  static const keys = {_bodyKey, _savedAtKey};
}

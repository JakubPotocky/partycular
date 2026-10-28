import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'event.dart';
import 'events_api.dart';
import 'events_cache.dart';

/// A loaded set of events and where it came from.
@immutable
class EventsSnapshot {
  const EventsSnapshot({required this.events, required this.updatedAt, this.isOffline = false});

  /// Published events, sorted by start time.
  final List<Event> events;

  /// When the data was fetched from the server.
  final DateTime updatedAt;

  /// True when the server was unreachable and cached data is shown.
  final bool isOffline;
}

/// Loads events from the API and falls back to the device cache.
class EventsRepository {
  EventsRepository({required this._api, required this._cache, DateTime Function()? now}) : _now = now ?? DateTime.now;

  final EventsApi _api;
  final EventsCache _cache;
  final DateTime Function() _now;

  /// Fetches fresh events. If that fails, returns cached events flagged as
  /// offline; rethrows only when there is nothing cached to show.
  Future<EventsSnapshot> load() async {
    try {
      final json = await _api.fetchEventsJson();
      final fetchedAt = _now();
      final events = parseEvents(json, _api.baseUri);
      await _cache.write(json, fetchedAt);
      return EventsSnapshot(events: events, updatedAt: fetchedAt);
    } on EventsApiException {
      final cached = _cache.read();
      if (cached == null) rethrow;
      return EventsSnapshot(events: parseEvents(cached.json, _api.baseUri), updatedAt: cached.savedAt, isOffline: true);
    }
  }

  /// Parses an API body, skipping (and logging) malformed records so that one
  /// bad row never hides the whole programme.
  @visibleForTesting
  static List<Event> parseEvents(String json, Uri baseUri) {
    final decoded = jsonDecode(json);
    if (decoded is! List<Object?>) return const [];
    final events = <Event>[];
    for (final item in decoded) {
      if (item is! Map<String, Object?>) continue;
      try {
        events.add(Event.fromJson(item, baseUri: baseUri));
      } on FormatException catch (error) {
        debugPrint('Skipping event record: $error');
      }
    }
    events.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return List.unmodifiable(events);
  }
}

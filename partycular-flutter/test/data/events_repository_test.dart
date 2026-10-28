import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:partycular/data/events_api.dart';
import 'package:partycular/data/events_cache.dart';
import 'package:partycular/data/events_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/fixtures.dart';

void main() {
  late EventsCache cache;
  final now = DateTime.utc(2026, 10, 28, 9);

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    cache = EventsCache(
      await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(allowList: EventsCache.keys),
      ),
    );
  });

  EventsRepository repository(MockClientHandler handler) => EventsRepository(
    api: EventsApi(client: MockClient(handler), baseUri: testBaseUri),
    cache: cache,
    now: () => now,
  );

  test('loads, sorts and caches events', () async {
    final body = eventsBody([
      eventJson(id: 2, startsAt: '2026-10-29T20:00:00Z'),
      eventJson(id: 1, startsAt: '2026-10-28T20:00:00Z'),
    ]);
    final snapshot = await repository((request) async {
      expect(request.url.toString(), 'https://partycular.eu/api/events');
      return _json(body);
    }).load();

    expect(snapshot.events.map((e) => e.id), [1, 2]);
    expect(snapshot.isOffline, isFalse);
    expect(snapshot.updatedAt, now);
    expect(cache.read()?.json, body);
  });

  test('skips malformed records instead of failing', () async {
    final body = eventsBody([eventJson(id: 1), eventJson(id: 2)..remove('startsAt')]);
    final snapshot = await repository((_) async => _json(body)).load();
    expect(snapshot.events.map((e) => e.id), [1]);
  });

  test('falls back to cached events when offline', () async {
    await cache.write(eventsBody([eventJson(id: 7)]), DateTime.utc(2026, 10, 27));
    final snapshot = await repository((_) async => throw http.ClientException('offline')).load();
    expect(snapshot.isOffline, isTrue);
    expect(snapshot.events.single.id, 7);
    expect(snapshot.updatedAt, DateTime.utc(2026, 10, 27));
  });

  test('falls back to the cache on server errors', () async {
    await cache.write(eventsBody([eventJson(id: 7)]), DateTime.utc(2026, 10, 27));
    final snapshot = await repository((_) async => http.Response('{"error":"x"}', 500)).load();
    expect(snapshot.isOffline, isTrue);
  });

  test('throws when offline with nothing cached', () async {
    await expectLater(
      repository((_) async => http.Response('nope', 503)).load(),
      throwsA(isA<EventsApiException>().having((e) => e.statusCode, 'statusCode', 503)),
    );
  });

  test('rejects a body that is not a list', () async {
    await expectLater(repository((_) async => _json('{"error":"x"}')).load(), throwsA(isA<EventsApiException>()));
  });
}

http.Response _json(String body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

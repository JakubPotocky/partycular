import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/events_api.dart';
import '../data/events_cache.dart';
import '../data/events_repository.dart';
import '../data/map_style_repository.dart';

/// Overridden in `main()` with the instance created before `runApp`.
final sharedPreferencesProvider = Provider<SharedPreferencesWithCache>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// The current time; overridden in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final eventsRepositoryProvider = Provider<EventsRepository>(
  (ref) => EventsRepository(
    api: EventsApi(client: ref.watch(httpClientProvider)),
    cache: EventsCache(ref.watch(sharedPreferencesProvider)),
    now: ref.watch(clockProvider),
  ),
);

final mapStyleRepositoryProvider = Provider<MapStyleRepository>(
  (ref) => MapStyleRepository(client: ref.watch(httpClientProvider), prefs: ref.watch(sharedPreferencesProvider)),
);

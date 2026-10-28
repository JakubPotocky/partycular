import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers.dart';
import 'data/events_cache.dart';
import 'data/map_style_repository.dart';
import 'features/settings/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (prefs, _) = await (
    SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {ThemePreferenceNotifier.storageKey, ...EventsCache.keys, ...MapStyleRepository.keys},
      ),
    ),
    initializeDateFormatting('sk'),
  ).wait;

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      // Failed loads are retried a few times with backoff, then reported.
      retry: (retryCount, error) => retryCount < 3 ? Duration(seconds: 2 << retryCount) : null,
      child: const PartycularApp(),
    ),
  );
}

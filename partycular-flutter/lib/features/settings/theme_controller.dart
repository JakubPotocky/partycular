import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

enum ThemePreference { light, dark, system }

/// The chosen appearance. Dark is the default, as on the web map.
final themePreferenceProvider = NotifierProvider<ThemePreferenceNotifier, ThemePreference>(ThemePreferenceNotifier.new);

class ThemePreferenceNotifier extends Notifier<ThemePreference> {
  /// Same storage key as the web app's `localStorage` entry.
  static const storageKey = 'partycular-theme';

  @override
  ThemePreference build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(storageKey);
    return ThemePreference.values.asNameMap()[stored] ?? ThemePreference.dark;
  }

  Future<void> set(ThemePreference preference) async {
    state = preference;
    await ref.read(sharedPreferencesProvider).setString(storageKey, preference.name);
  }
}

extension ThemePreferenceMode on ThemePreference {
  ThemeMode get themeMode => switch (this) {
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
    ThemePreference.system => ThemeMode.system,
  };
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/strings.dart';
import 'core/theme/app_theme.dart';
import 'features/map/map_screen.dart';
import 'features/settings/theme_controller.dart';

class PartycularApp extends ConsumerWidget {
  const PartycularApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themePreferenceProvider).themeMode,
      locale: const Locale('sk'),
      supportedLocales: const [Locale('sk')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const MapScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';

/// Builds Material themes from the PARTYCULAR palette.
abstract final class AppTheme {
  static const fontFamily = 'Inter';

  static ThemeData light() => _build(AppPalette.light);
  static ThemeData dark() => _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.accent,
      onSecondary: p.onAccent,
      error: p.danger,
      onError: p.background,
      surface: p.panel,
      onSurface: p.text,
      onSurfaceVariant: p.muted,
      surfaceContainerHighest: p.panel2,
      outline: p.border,
      outlineVariant: p.border,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: p.background,
      splashFactory: InkSparkle.splashFactory,
      extensions: [p],
    );
    final text = base.textTheme.apply(bodyColor: p.text, displayColor: p.text);
    return base.copyWith(
      textTheme: text.copyWith(
        headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.7),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      iconTheme: IconThemeData(color: p.text),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.panel,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.border,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.text,
        contentTextStyle: TextStyle(fontFamily: fontFamily, color: p.background, fontSize: 14),
        // The snack bar uses the inverted surface, so it takes the other theme's accent.
        actionTextColor: p.isDark ? AppPalette.light.accent : AppPalette.dark.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          minimumSize: const Size(0, 44),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          backgroundColor: p.panel2,
          side: BorderSide(color: p.border),
          minimumSize: const Size(0, 44),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: p.text, borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(fontFamily: fontFamily, color: p.background, fontSize: 12),
      ),
    );
  }

  /// Status bar icons that stay readable over the map in each theme.
  static SystemUiOverlayStyle overlayStyle(AppPalette p) => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: p.isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: p.brightness,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: p.isDark ? Brightness.light : Brightness.dark,
  );
}

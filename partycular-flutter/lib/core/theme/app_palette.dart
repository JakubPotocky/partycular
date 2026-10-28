import 'package:flutter/material.dart';

/// Design tokens of the public map, ported from the web app's CSS variables.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.panel,
    required this.panel2,
    required this.border,
    required this.muted,
    required this.text,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.live,
    required this.mapLand,
  });

  static const dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF17232E),
    panel: Color(0xFF1E2D39),
    panel2: Color(0xFF2A3E4D),
    border: Color(0xFF405564),
    muted: Color(0xFFB0C1CE),
    text: Color(0xFFEDF4FA),
    accent: Color(0xFF75C7FF),
    onAccent: Color(0xFF17232E),
    danger: Color(0xFFFF8F87),
    live: Color(0xFFFF5C7A),
    mapLand: Color(0xFF202C37),
  );

  static const light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFEEF3F5),
    panel: Color(0xFFFFFFFF),
    panel2: Color(0xFFE4EDF1),
    border: Color(0xFFC5D4DB),
    muted: Color(0xFF576D79),
    text: Color(0xFF132C38),
    accent: Color(0xFF168FD3),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFC4372D),
    live: Color(0xFFE0264A),
    mapLand: Color(0xFFF1EEE8),
  );

  final Brightness brightness;
  final Color background;

  /// Surface of floating "glass" panels.
  final Color panel;

  /// Secondary surface: chips, inactive buttons.
  final Color panel2;
  final Color border;
  final Color muted;
  final Color text;
  final Color accent;
  final Color onAccent;
  final Color danger;
  final Color live;

  /// Land colour of the basemap, shown before tiles arrive.
  final Color mapLand;

  bool get isDark => brightness == Brightness.dark;

  static AppPalette of(BuildContext context) => Theme.of(context).extension<AppPalette>()!;

  @override
  AppPalette copyWith({
    Color? background,
    Color? panel,
    Color? panel2,
    Color? border,
    Color? muted,
    Color? text,
    Color? accent,
    Color? onAccent,
    Color? danger,
    Color? live,
    Color? mapLand,
  }) => AppPalette(
    brightness: brightness,
    background: background ?? this.background,
    panel: panel ?? this.panel,
    panel2: panel2 ?? this.panel2,
    border: border ?? this.border,
    muted: muted ?? this.muted,
    text: text ?? this.text,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    danger: danger ?? this.danger,
    live: live ?? this.live,
    mapLand: mapLand ?? this.mapLand,
  );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: Color.lerp(background, other.background, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panel2: Color.lerp(panel2, other.panel2, t)!,
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      text: Color.lerp(text, other.text, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      live: Color.lerp(live, other.live, t)!,
      mapLand: Color.lerp(mapLand, other.mapLand, t)!,
    );
  }
}

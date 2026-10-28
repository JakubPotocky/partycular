import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';

/// The floating, blurred panel used for every control over the map
/// (the web app's `.glass` class).
///
/// The blur joins the nearest [BackdropGroup], so panels over the same
/// backdrop are blurred in one pass. Panels in one group must not overlap.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.padding = EdgeInsets.zero,
    this.shape = BoxShape.rectangle,
    this.opacity = 0.9,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final BoxShape shape;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isCircle = shape == BoxShape.circle;
    final radius = isCircle ? null : borderRadius;
    final blurred = BackdropFilter.grouped(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.panel.withValues(alpha: opacity),
          shape: shape,
          borderRadius: radius,
          border: Border.all(color: p.border.withValues(alpha: p.isDark ? 1 : 0.7)),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
    // The shadow sits outside the clip, so it is painted by an outer box.
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: p.isDark ? 0.27 : 0.12),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isCircle ? ClipOval(child: blurred) : ClipRRect(borderRadius: borderRadius, child: blurred),
    );
  }
}

/// A round glass button, e.g. settings or my-location.
class GlassCircleButton extends StatelessWidget {
  const GlassCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 48,
    this.iconSize = 22,
    this.iconColor,
    this.busy = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: GlassPanel(
          shape: BoxShape.circle,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: busy ? null : onPressed,
              child: SizedBox.square(
                dimension: size,
                child: Center(
                  child: busy
                      ? SizedBox.square(
                          dimension: iconSize - 4,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: iconColor ?? p.accent),
                        )
                      : Icon(icon, size: iconSize, color: iconColor ?? p.text),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

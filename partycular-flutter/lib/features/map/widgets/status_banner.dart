import 'package:flutter/material.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../ui/glass_panel.dart';

/// A compact floating notice over the map (`.map-notice` / `.day-empty`).
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.icon,
    this.busy = false,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  final String message;
  final IconData? icon;
  final bool busy;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: GlassPanel(
        borderRadius: BorderRadius.circular(16),
        padding: EdgeInsets.fromLTRB(16, 10, onDismiss == null ? 16 : 4, 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: p.accent),
                ),
              )
            else if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(icon, size: 18, color: p.muted),
              ),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message, style: TextStyle(color: p.text, fontSize: 14, height: 1.35)),
                  if (actionLabel != null)
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                        alignment: Alignment.centerLeft,
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      child: Text(actionLabel!),
                    ),
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                tooltip: S.close,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded, size: 18, color: p.muted),
              ),
          ],
        ),
      ),
    );
  }
}

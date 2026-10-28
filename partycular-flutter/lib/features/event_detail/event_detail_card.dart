import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config.dart';
import '../../core/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../data/event.dart';
import '../../ui/event_image.dart';
import '../../ui/glass_panel.dart';
import '../../ui/links.dart';
import '../events/event_formatters.dart';
import 'photo_viewer.dart';

/// The floating detail card of the selected event (`.event-card`).
class EventDetailCard extends StatefulWidget {
  const EventDetailCard({super.key, required this.event, required this.now, required this.onClose});

  final Event event;
  final DateTime now;
  final VoidCallback onClose;

  @override
  State<EventDetailCard> createState() => _EventDetailCardState();
}

class _EventDetailCardState extends State<EventDetailCard> {
  bool _infoOpen = false;

  Future<void> _share(BuildContext buttonContext) async {
    final event = widget.event;
    final box = buttonContext.findRenderObject() as RenderBox?;
    final link = event.sourceUrl ?? event.ticketUrl ?? AppConfig.apiBaseUri;
    await SharePlus.instance.share(
      ShareParams(
        subject: event.name,
        text: '${event.name}\n${EventFormat.schedule(event)}\n${event.venue}\n$link',
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final event = widget.event;
    final isLive = event.isLiveAt(widget.now);

    return Semantics(
      container: true,
      label: S.eventDetail,
      child: GlassPanel(
        borderRadius: BorderRadius.circular(24),
        opacity: 0.96,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 12, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (event.category.isNotEmpty)
                    Text(
                      event.category.toUpperCase(),
                      style: TextStyle(color: p.accent, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
                    ),
                  if (isLive) ...[const SizedBox(width: 10), _LiveBadge(color: p.live)],
                  const Spacer(),
                  IconButton(
                    tooltip: S.close,
                    onPressed: widget.onClose,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(backgroundColor: p.panel2),
                    icon: Icon(Icons.close_rounded, size: 19, color: p.muted),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.name,
                      style: TextStyle(
                        color: p.text,
                        fontSize: 21,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  _ArtTile(event: event),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(icon: Icons.schedule_rounded, text: EventFormat.schedule(event)),
              _InfoRow(
                icon: Icons.place_outlined,
                text: [
                  event.venue,
                  if (event.district.isNotEmpty && event.district != event.venue) event.district,
                ].where((part) => part.isNotEmpty).join(' · '),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (event.ticketUrl case final ticketUrl?)
                    FilledButton.icon(
                      onPressed: () => openExternal(context, ticketUrl),
                      icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                      label: const Text(S.tickets),
                    ),
                  if (event.sourceUrl case final sourceUrl?)
                    OutlinedButton.icon(
                      onPressed: () => openExternal(context, sourceUrl),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text(S.eventPage),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => openExternal(context, directionsUri(event.latitude, event.longitude)),
                    icon: const Icon(Icons.directions_outlined, size: 18),
                    label: const Text(S.navigate),
                  ),
                  Builder(
                    builder: (buttonContext) => OutlinedButton.icon(
                      onPressed: () => _share(buttonContext),
                      icon: const Icon(Icons.ios_share_rounded, size: 18),
                      label: const Text(S.share),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _Chip(text: event.price.isNotEmpty ? event.price : S.priceUnknown, color: p.accent),
                  if (event.tags.isNotEmpty) _Chip(text: event.tags.first),
                ],
              ),
              if (event.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                _InfoToggle(open: _infoOpen, onTap: () => setState(() => _infoOpen = !_infoOpen)),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _infoOpen
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SelectableText(
                            event.description,
                            style: TextStyle(color: p.text, fontSize: 14, height: 1.6),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtTile extends StatelessWidget {
  const _ArtTile({required this.event});

  final Event event;

  static const size = 84.0;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = event.imageUrl != null;
    final tile = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: event.color.withValues(alpha: 0.45)),
      ),
      child: EventImage(event: event, size: size, initialsScale: 0.4),
    );
    if (!hasPhoto) return ExcludeSemantics(child: tile);
    return Semantics(
      button: true,
      label: S.showPhoto,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => showPhotoViewer(context, event),
        child: Hero(tag: 'photo-${event.id}', child: tile),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: p.muted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: p.text.withValues(alpha: 0.85), fontSize: 13.5, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: p.panel2,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color ?? p.text, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            S.liveNow,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoToggle extends StatelessWidget {
  const _InfoToggle({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final color = open ? p.accent : p.text;
    return Semantics(
      button: true,
      expanded: open,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(foregroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: color),
            const SizedBox(width: 7),
            const Text(S.info),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.expand_more_rounded, size: 18, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../core/strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/event.dart';
import '../../../ui/event_image.dart';
import '../event_clustering.dart';
import 'event_pin.dart';

/// Event pins, merged into count bubbles where they would overlap.
///
/// Lives inside [FlutterMap] and re-clusters as the zoom changes. The
/// selected event is never clustered and is drawn on top.
class EventMarkersLayer extends StatelessWidget {
  const EventMarkersLayer({
    super.key,
    required this.events,
    required this.selected,
    required this.userLocation,
    required this.onSelect,
    required this.onCluster,
  });

  final List<Event> events;
  final Event? selected;
  final LatLng? userLocation;
  final ValueChanged<Event> onSelect;
  final ValueChanged<EventCluster> onCluster;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final palette = AppPalette.of(context);
    final zoom = camera.zoom;
    final clusters = clusterEvents(
      [
        for (final e in events)
          if (e.id != selected?.id) e,
      ],
      project: (point) => camera.projectAtZoom(point, zoom),
      unproject: (pixel) => camera.unprojectAtZoom(pixel, zoom),
    );
    return MarkerLayer(
      markers: [
        if (userLocation case final location?) userLocationMarker(location, palette.accent),
        for (final cluster in clusters)
          if (cluster.isSingle)
            eventMarker(cluster.events.single, selected: false, onTap: () => onSelect(cluster.events.single))
          else
            _clusterMarker(cluster),
        if (selected case final event?) eventMarker(event, selected: true, onTap: () => onSelect(event)),
      ],
    );
  }

  Marker _clusterMarker(EventCluster cluster) => Marker(
    key: ValueKey('cluster-${cluster.events.map((e) => e.id).join('-')}'),
    point: cluster.center,
    width: PinGeometry.width,
    height: _ClusterPin.boxHeight,
    child: _ClusterPin(cluster: cluster, onTap: () => onCluster(cluster)),
  );
}

class _ClusterPin extends StatelessWidget {
  const _ClusterPin({required this.cluster, required this.onTap});

  static const diameter = 56.0;
  static const boxHeight = diameter + 2 * (PinGeometry.labelGap + PinGeometry.labelReserve);

  final EventCluster cluster;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final events = cluster.events;
    final lead = events.first;
    final count = events.length;
    final label = cluster.isSameSpot && lead.venue.isNotEmpty ? lead.venue : S.eventCount(count);

    return Semantics(
      button: true,
      label: '${S.eventCount(count)}: ${events.map((e) => e.name).join(', ')}',
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: boxHeight / 2 - diameter / 2,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: diameter + 16,
                    height: diameter,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // A hint of the stacked events behind the bubble.
                        for (final (index, event) in events.skip(1).take(2).indexed)
                          Positioned(
                            left: index == 0 ? 0 : null,
                            right: index == 1 ? 0 : null,
                            child: _Disc(event: event, size: diameter - 12, borderColor: event.color),
                          ),
                        _Disc(
                          event: lead,
                          size: diameter,
                          borderColor: p.accent,
                          overlay: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              shadows: [Shadow(blurRadius: 6)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: PinGeometry.labelGap),
                  Container(
                    constraints: const BoxConstraints(maxWidth: PinGeometry.width),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0x90070A07), borderRadius: BorderRadius.circular(5)),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.event, required this.size, required this.borderColor, this.overlay});

  final Event event;
  final double size;
  final Color borderColor;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            EventImage(event: event, size: size, showInitials: overlay == null),
            if (overlay != null) ...[const ColoredBox(color: Color(0x8C070A07)), Center(child: overlay)],
          ],
        ),
      ),
    );
  }
}

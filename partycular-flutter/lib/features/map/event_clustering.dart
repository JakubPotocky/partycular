import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../data/event.dart';

/// One or more events drawn as a single marker.
@immutable
class EventCluster {
  const EventCluster(this.events, this.center);

  /// In the order they were given (by start time).
  final List<Event> events;
  final LatLng center;

  bool get isSingle => events.length == 1;

  /// True when all events are at practically the same spot, so zooming in
  /// can never separate them.
  bool get isSameSpot {
    const distance = Distance();
    final first = LatLng(events.first.latitude, events.first.longitude);
    return events.every((e) => distance.as(LengthUnit.Meter, first, LatLng(e.latitude, e.longitude)) < 30);
  }
}

/// Groups events whose pins would overlap on screen.
///
/// Agglomerative: the two closest groups (by centroid) merge while they are
/// within [radius] pixels, so no remaining marker overlaps another. [project]
/// maps coordinates to pixels at the current zoom, so the result changes only
/// when zooming, never while panning. Fine for the few dozen events of a day.
List<EventCluster> clusterEvents(
  List<Event> events, {
  required Offset Function(LatLng point) project,
  required LatLng Function(Offset pixel) unproject,
  double radius = 64,
}) {
  final groups = [
    for (final (index, e) in events.indexed) _Group([index], project(LatLng(e.latitude, e.longitude))),
  ];
  while (groups.length > 1) {
    var best = (a: -1, b: -1, distance: radius);
    for (var a = 0; a < groups.length; a++) {
      for (var b = a + 1; b < groups.length; b++) {
        final distance = (groups[a].center - groups[b].center).distance;
        if (distance < best.distance) best = (a: a, b: b, distance: distance);
      }
    }
    if (best.a < 0) break;
    groups[best.a] = groups[best.a].merge(groups.removeAt(best.b));
  }
  return [
    for (final group in groups)
      if (group.members.length == 1)
        EventCluster([events[group.members.single]], _position(events[group.members.single]))
      else
        EventCluster([for (final m in group.members..sort()) events[m]], unproject(group.center)),
  ];
}

LatLng _position(Event event) => LatLng(event.latitude, event.longitude);

class _Group {
  _Group(this.members, this.center);

  final List<int> members;
  final Offset center;

  _Group merge(_Group other) {
    final total = members.length + other.members.length;
    return _Group([
      ...members,
      ...other.members,
    ], (center * members.length.toDouble() + other.center * other.members.length.toDouble()) / total.toDouble());
  }
}

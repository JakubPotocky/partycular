import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:partycular/features/map/event_clustering.dart';

import '../support/fixtures.dart';

void main() {
  // Treat (latitude, longitude) as pixels so distances are easy to reason about.
  Offset project(LatLng p) => Offset(p.longitude, p.latitude);
  LatLng unproject(Offset o) => LatLng(o.dy, o.dx);

  List<EventCluster> cluster(List<(double, double)> points) => clusterEvents(
    [for (final (i, (x, y)) in points.indexed) eventFixture(id: i, latitude: y, longitude: x)],
    project: project,
    unproject: unproject,
    radius: 50,
  );

  test('keeps distant pins apart', () {
    final result = cluster([(0, 0), (100, 0), (0, 100)]);
    expect(result, hasLength(3));
    expect(result.every((c) => c.isSingle), isTrue);
  });

  test('merges overlapping pins at their centroid', () {
    final result = cluster([(0, 0), (20, 0), (200, 0)]);
    expect(result, hasLength(2));
    final merged = result.firstWhere((c) => !c.isSingle);
    expect(merged.events.map((e) => e.id), [0, 1]);
    expect(merged.center.longitude, 10);
  });

  test('merges chains until no two markers overlap', () {
    // A and C are 60 px apart, but once A and B merge at x=15, C is only 45 px
    // from that marker and joins it.
    final result = cluster([(0, 0), (30, 0), (60, 0)]);
    expect(result.single.events, hasLength(3));
  });

  test('detects events at the same venue', () {
    final sameVenue = EventCluster([
      eventFixture(id: 1),
      eventFixture(id: 2, latitude: 48.14071, longitude: 17.10021),
    ], const LatLng(48.1407, 17.1002));
    expect(sameVenue.isSameSpot, isTrue);
    final apart = EventCluster([
      eventFixture(id: 1),
      eventFixture(id: 2, latitude: 48.1500, longitude: 17.1100),
    ], const LatLng(48.145, 17.105));
    expect(apart.isSameSpot, isFalse);
  });
}

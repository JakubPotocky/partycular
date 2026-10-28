import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/providers.dart';
import '../../data/map_style_repository.dart';

/// Light and dark basemap themes, built once and switched instantly.
final mapStylesProvider = FutureProvider<MapStyles>((ref) => ref.watch(mapStyleRepositoryProvider).load());

enum LocateResult { found, serviceDisabled, denied, deniedForever, failed }

/// The user's last known position, shown as a dot once they ask for it.
final userLocationProvider = NotifierProvider<UserLocationNotifier, LatLng?>(UserLocationNotifier.new);

class UserLocationNotifier extends Notifier<LatLng?> {
  @override
  LatLng? build() => null;

  /// Asks for permission when needed and reads the current position.
  Future<LocateResult> locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return LocateResult.serviceDisabled;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return LocateResult.deniedForever;
      if (permission == LocationPermission.denied) return LocateResult.denied;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      state = LatLng(position.latitude, position.longitude);
      return LocateResult.found;
    } on Exception {
      return LocateResult.failed;
    }
  }
}

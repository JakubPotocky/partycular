import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Static configuration shared across the app.
///
/// The API host can be overridden at build time, e.g. for a local backend:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000`.
abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://partycular.eu');

  static Uri get apiBaseUri => Uri.parse(apiBaseUrl);

  /// TileJSON of the OpenFreeMap planet tiles used by the web app.
  static final Uri tileJsonUri = Uri.parse('https://tiles.openfreemap.org/planet');

  /// Central Bratislava, the same point the web map starts from.
  static const LatLng cityCenter = LatLng(48.1464, 17.1121);

  static const double initialZoom = 13;
  static const double homeZoom = 14;
  static const double focusZoom = 15;
  static const double minZoom = 10;
  static const double maxZoom = 20;

  /// Keeps the camera around the Bratislava region, where all events are.
  static final LatLngBounds cameraBounds = LatLngBounds(const LatLng(47.85, 16.70), const LatLng(48.45, 17.55));

  static const Duration requestTimeout = Duration(seconds: 15);
}

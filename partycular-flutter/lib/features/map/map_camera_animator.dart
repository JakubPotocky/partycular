import 'package:flutter/animation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Smoothly moves a [MapController], like MapLibre's `easeTo` on the web.
class MapCameraAnimator {
  MapCameraAnimator({required this._controller, required TickerProvider vsync})
    : _animation = AnimationController(vsync: vsync);

  static const defaultDuration = Duration(milliseconds: 650);

  final MapController _controller;
  final AnimationController _animation;
  VoidCallback? _tick;

  MapCamera get camera => _controller.camera;

  /// Stops a running animation, e.g. when the user grabs the map.
  void stop() {
    _animation.stop();
    final tick = _tick;
    if (tick != null) _animation.removeListener(tick);
    _tick = null;
  }

  /// Animates to [center] and [zoom]. A zero [duration] jumps immediately
  /// (used when the platform asks for reduced motion).
  Future<void> animateTo(
    LatLng center,
    double zoom, {
    Duration duration = defaultDuration,
    Curve curve = Curves.easeInOutCubic,
  }) async {
    stop();
    final target = camera.clampZoom(zoom);
    if (duration == Duration.zero) {
      _controller.move(center, target);
      return;
    }
    final start = camera;
    final latitude = Tween(begin: start.center.latitude, end: center.latitude);
    final longitude = Tween(begin: start.center.longitude, end: center.longitude);
    final zoomTween = Tween(begin: start.zoom, end: target);
    final curved = CurvedAnimation(parent: _animation, curve: curve);
    void tick() =>
        _controller.move(LatLng(latitude.evaluate(curved), longitude.evaluate(curved)), zoomTween.evaluate(curved));
    _tick = tick;
    _animation
      ..duration = duration
      ..addListener(tick);
    try {
      await _animation.forward(from: 0).orCancel;
    } on TickerCanceled {
      // Interrupted by another animation or a gesture.
    } finally {
      _animation.removeListener(tick);
      if (identical(_tick, tick)) _tick = null;
    }
  }

  /// The camera centre at [zoom] that shows [point] at [screenPoint]
  /// (in logical pixels from the map's top-left corner).
  LatLng centerPlacing(LatLng point, double zoom, Offset screenPoint) {
    final projected = camera.projectAtZoom(point, zoom);
    final viewCenter = camera.size.center(Offset.zero);
    return camera.unprojectAtZoom(projected - (screenPoint - viewCenter), zoom);
  }

  void dispose() {
    stop();
    _animation.dispose();
  }
}

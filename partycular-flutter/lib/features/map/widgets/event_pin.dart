import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../data/event.dart';
import '../../../ui/event_image.dart';

/// Geometry shared by the pin widget and its [Marker] box.
abstract final class PinGeometry {
  static const width = 130.0;
  static const labelGap = 8.0;
  static const selectedLabelGap = 28.0;
  static const labelReserve = 52.0;

  /// How far a selected pin rises so its tail points at the venue.
  static double lift(double diameter) => diameter / 2 + 18;

  /// The marker box is symmetric around the venue so the circle's centre
  /// (or the selected tail tip) sits exactly on the coordinates.
  static double boxHeight(double diameter) =>
      diameter + 2 * (lift(diameter) > labelReserve ? lift(diameter) : labelReserve) + 2 * selectedLabelGap;
}

/// Builds the flutter_map marker for [event].
Marker eventMarker(Event event, {required bool selected, required VoidCallback onTap}) {
  final diameter = event.markerSize.diameter;
  return Marker(
    key: ValueKey('event-${event.id}'),
    point: LatLng(event.latitude, event.longitude),
    width: PinGeometry.width,
    height: PinGeometry.boxHeight(diameter),
    child: EventPin(event: event, selected: selected, onTap: onTap),
  );
}

/// A round event marker with photo or initials and a short label below.
/// Mirrors the web app's `.event-pin`.
class EventPin extends StatefulWidget {
  const EventPin({super.key, required this.event, required this.selected, required this.onTap});

  final Event event;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<EventPin> createState() => _EventPinState();
}

class _EventPinState extends State<EventPin> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final selected = widget.selected;
    final diameter = event.markerSize.diameter;
    final boxHeight = PinGeometry.boxHeight(diameter);
    const duration = Duration(milliseconds: 220);

    return Semantics(
      button: true,
      selected: selected,
      label: '${event.name}, ${event.venue}',
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedPositioned(
            duration: duration,
            curve: Curves.easeOutBack,
            top: boxHeight / 2 - diameter / 2 - (selected ? PinGeometry.lift(diameter) : 0),
            left: 0,
            right: 0,
            child: GestureDetector(
              onTapDown: (_) => _setPressed(true),
              onTapUp: (_) => _setPressed(false),
              onTapCancel: () => _setPressed(false),
              onTap: widget.onTap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: _pressed && !selected ? 1.12 : 1,
                    duration: const Duration(milliseconds: 180),
                    child: _PinCircle(event: event, selected: selected),
                  ),
                  AnimatedContainer(
                    duration: duration,
                    height: selected ? PinGeometry.selectedLabelGap : PinGeometry.labelGap,
                    alignment: Alignment.topCenter,
                    child: selected
                        ? Transform.translate(
                            offset: const Offset(0, -1),
                            child: CustomPaint(size: const Size(24, 19), painter: _TailPainter(event.color)),
                          )
                        : null,
                  ),
                  if (event.markerSize.showsLabel) _PinLabel(text: event.pinLabel),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinCircle extends StatelessWidget {
  const _PinCircle({required this.event, required this.selected});

  final Event event;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = event.color;
    final diameter = event.markerSize.diameter;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: eventArtGradient(color),
        boxShadow: selected
            ? [
                BoxShadow(color: color.withValues(alpha: 0.22), spreadRadius: 5),
                BoxShadow(color: Colors.black.withValues(alpha: 0.27), blurRadius: 25, offset: const Offset(0, 6)),
              ]
            : [
                BoxShadow(color: color.withValues(alpha: 0.08), spreadRadius: 5),
                BoxShadow(color: color.withValues(alpha: 0.26), blurRadius: 25),
              ],
      ),
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: ClipOval(
        child: EventImage(event: event, size: diameter, initialsScale: 0.32),
      ),
    );
  }
}

class _PinLabel extends StatelessWidget {
  const _PinLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: PinGeometry.width),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: const Color(0x90070A07), borderRadius: BorderRadius.circular(5)),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.35,
          shadows: [
            Shadow(blurRadius: 4, offset: Offset(0, 1)),
            Shadow(blurRadius: 6),
          ],
        ),
      ),
    );
  }
}

/// The downward triangle under a selected pin.
class _TailPainter extends CustomPainter {
  const _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => oldDelegate.color != color;
}

/// The dot marking the user's position.
Marker userLocationMarker(LatLng point, Color color) => Marker(
  key: const ValueKey('user-location'),
  point: point,
  width: 28,
  height: 28,
  child: IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), spreadRadius: 8)],
      ),
    ),
  ),
);

import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';

/// The gradient "P" pin mark, drawn as vectors so it is sharp at any size.
class PartycularMark extends StatelessWidget {
  const PartycularMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: const PartycularMarkPainter());
}

class PartycularMarkPainter extends CustomPainter {
  const PartycularMarkPainter({this.inset = 0});

  /// Fraction of the canvas left empty on each side (for launcher icons).
  final double inset;

  static const gradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF6A2CFF), Color(0xFFE61E9C), Color(0xFFFF5A36), Color(0xFFFFB21A)],
    stops: [0, 0.4, 0.7, 1],
  );

  /// The mark is a circle fused with its lower-left quadrant (a map pin
  /// pointing down-left), with a round hole: together they read as a "P".
  static Path markPath(Size size) {
    final s = size.shortestSide;
    final center = Offset(0.544 * s, 0.444 * s);
    final radius = 0.344 * s;
    final body = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    final quadrant = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(center.dx - radius, center.dy, center.dx, center.dy + radius),
          bottomLeft: Radius.circular(0.07 * s),
        ),
      );
    final hole = Path()..addOval(Rect.fromCircle(center: center, radius: 0.14 * s));
    return Path.combine(PathOperation.difference, Path.combine(PathOperation.union, body, quadrant), hole);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Fit the mark's actual bounds (it is not centred in its unit square)
    // into the available square, centred.
    final unit = markPath(const Size.square(1));
    final bounds = unit.getBounds();
    final side = size.shortestSide * (1 - 2 * inset);
    final scale = side / bounds.longestSide;
    final matrix = Matrix4.identity()
      ..translateByDouble(size.width / 2, size.height / 2, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-bounds.center.dx, -bounds.center.dy, 0, 1);
    final path = unit.transform(matrix.storage);
    final paint = Paint()
      ..isAntiAlias = true
      ..shader = gradient.createShader(path.getBounds());
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(PartycularMarkPainter oldDelegate) => oldDelegate.inset != inset;
}

/// "PARTY" + accent-coloured "CULAR".
class PartycularWordmark extends StatelessWidget {
  const PartycularWordmark({super.key, this.fontSize = 28});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: -fontSize * 0.056,
      height: 1,
      color: p.text,
    );
    return Text.rich(
      TextSpan(
        text: 'PARTY',
        children: [
          TextSpan(
            text: 'CULAR',
            style: TextStyle(color: p.accent),
          ),
        ],
      ),
      style: style,
      semanticsLabel: 'PARTYCULAR',
      maxLines: 1,
    );
  }
}

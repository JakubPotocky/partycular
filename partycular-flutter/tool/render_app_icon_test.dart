// Renders the launcher icon sources from the vector logo.
// Run: flutter test tool/render_app_icon_test.dart
// then: dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:partycular/core/theme/app_palette.dart';
import 'package:partycular/ui/partycular_logo.dart';

const _size = 1024.0;

Future<void> _render(String path, {required double inset, Color? background}) async {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  if (background != null) canvas.drawRect(const Rect.fromLTWH(0, 0, _size, _size), Paint()..color = background);
  PartycularMarkPainter(inset: inset).paint(canvas, const Size.square(_size));
  final image = await recorder.endRecording().toImage(_size.toInt(), _size.toInt());
  final bytes = await image.toByteData(format: ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('render launcher icon sources', () async {
    // Full-bleed icon (iOS, legacy Android, web), on the dark map colour.
    await _render('assets/icon/app_icon.png', inset: 0.2, background: AppPalette.dark.background);
    // Android adaptive foreground: the mark inside the 66 % safe zone.
    await _render('assets/icon/app_icon_foreground.png', inset: 0.27);
  });
}

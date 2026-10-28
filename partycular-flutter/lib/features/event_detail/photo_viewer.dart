import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../data/event.dart';

/// Opens the event's full, uncropped photo with pinch-to-zoom.
Future<void> showPhotoViewer(BuildContext context, Event event) {
  final url = event.imageUrl;
  if (url == null) return Future.value();
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      barrierDismissible: true,
      barrierLabel: S.close,
      pageBuilder: (context, _, _) => _PhotoViewer(event: event, url: url),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.event, required this.url});

  final Event event;
  final Uri url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(
                  child: Semantics(
                    image: true,
                    label: event.name,
                    child: Hero(
                      tag: 'photo-${event.id}',
                      child: CachedNetworkImage(
                        imageUrl: url.toString(),
                        fit: BoxFit.contain,
                        errorWidget: (_, _, _) =>
                            const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton.filled(
                  tooltip: S.close,
                  style: IconButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

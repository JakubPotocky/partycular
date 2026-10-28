import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/event.dart';

/// An event photo cropped like the web app (`object-fit: cover` with the
/// admin's focus point and zoom). Falls back to the coloured initials when
/// there is no photo or it fails to load.
class EventImage extends StatelessWidget {
  const EventImage({
    super.key,
    required this.event,
    required this.size,
    this.initialsScale = 0.34,
    this.showInitials = true,
  });

  final Event event;

  /// Width of the box, used to decode the image at display resolution.
  final double size;
  final double initialsScale;

  /// When false, the fallback is only the tinted gradient.
  final bool showInitials;

  @override
  Widget build(BuildContext context) {
    final url = event.imageUrl;
    final Widget fallback = showInitials
        ? EventInitials(event: event, fontSize: size * initialsScale)
        : DecoratedBox(decoration: BoxDecoration(gradient: eventArtGradient(event.color)));
    if (url == null) return fallback;
    final cacheWidth = (size * event.imageZoom * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRect(
      child: CachedNetworkImage(
        imageUrl: url.toString(),
        memCacheWidth: cacheWidth,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 150),
        // Only the loaded photo is zoomed; the placeholder stays unscaled.
        imageBuilder: (_, image) => Transform.scale(
          scale: event.imageZoom,
          alignment: event.imageAlignment,
          child: Image(
            image: image,
            fit: BoxFit.cover,
            alignment: event.imageAlignment,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}

/// The dark, tinted disc content shown when an event has no photo.
class EventInitials extends StatelessWidget {
  const EventInitials({super.key, required this.event, required this.fontSize});

  final Event event;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: eventArtGradient(event.color)),
      child: Center(
        child: Text(
          event.initials,
          maxLines: 1,
          style: TextStyle(
            color: event.color,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// `linear-gradient(145deg, mix(color 25%, #121713), #101510)` from the web pins.
LinearGradient eventArtGradient(Color color) => LinearGradient(
  begin: const Alignment(-0.6, -1),
  end: const Alignment(0.6, 1),
  colors: [Color.lerp(const Color(0xFF121713), color, 0.25)!, const Color(0xFF101510)],
);

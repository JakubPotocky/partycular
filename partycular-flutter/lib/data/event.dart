import 'package:flutter/widgets.dart';

import '../core/time/calendar_day.dart';

/// Pin diameters in logical pixels, identical to the web app.
enum MarkerSize {
  small(38),
  medium(48),
  large(60),
  xlarge(74);

  const MarkerSize(this.diameter);

  final double diameter;

  /// Small pins hide their text label, like on the web.
  bool get showsLabel => this != small;

  static MarkerSize parse(Object? value) => values.firstWhere((size) => size.name == value, orElse: () => medium);
}

/// A published event, as returned by `GET /api/events`.
@immutable
class Event {
  const Event({
    required this.id,
    required this.name,
    required this.shortName,
    required this.venue,
    required this.district,
    required this.category,
    required this.startsAt,
    required this.endsAt,
    required this.price,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.imageX,
    required this.imageY,
    required this.imageZoom,
    required this.markerLabel,
    required this.markerSize,
    required this.color,
    required this.description,
    required this.tags,
    required this.sourceUrl,
    required this.ticketUrl,
  });

  /// Parses one API record. Relative image paths such as `/api/images/<id>`
  /// are resolved against [baseUri]. Throws [FormatException] for records
  /// missing data the map cannot do without.
  factory Event.fromJson(Map<String, Object?> json, {required Uri baseUri}) {
    final id = json['id'];
    final startsAt = _parseDate(json['startsAt']);
    final latitude = _parseDouble(json['latitude']);
    final longitude = _parseDouble(json['longitude']);
    final name = _string(json['name']);
    if (id is! int || startsAt == null || latitude == null || longitude == null || name.isEmpty) {
      throw FormatException('Incomplete event record', json['id']);
    }
    final endsAt = _parseDate(json['endsAt']);
    return Event(
      id: id,
      name: name,
      shortName: _string(json['shortName']),
      venue: _string(json['venue']),
      district: _string(json['district']),
      category: _string(json['category']),
      startsAt: startsAt,
      endsAt: endsAt != null && endsAt.isAfter(startsAt) ? endsAt : null,
      price: _string(json['price']),
      latitude: latitude,
      longitude: longitude,
      imageUrl: _resolveUrl(json['imageUrl'], baseUri),
      imageX: (_parseDouble(json['imageX']) ?? 50).clamp(0, 100).toDouble(),
      imageY: (_parseDouble(json['imageY']) ?? 50).clamp(0, 100).toDouble(),
      imageZoom: (_parseDouble(json['imageZoom']) ?? 1).clamp(1, 3).toDouble(),
      markerLabel: _string(json['markerLabel']),
      markerSize: MarkerSize.parse(json['markerSize']),
      color: parseHexColor(json['color']) ?? defaultColor,
      description: _string(json['description']),
      tags: _string(json['tags'])
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(growable: false),
      sourceUrl: _resolveUrl(json['sourceUrl'], baseUri),
      ticketUrl: _resolveUrl(json['ticketUrl'], baseUri),
    );
  }

  static const defaultColor = Color(0xFFC7FF2F);

  /// Events without an end time are assumed to run this long when deciding
  /// whether they are happening right now.
  static const assumedDuration = Duration(hours: 4);

  final int id;
  final String name;

  /// Up to 20 characters, shown under the pin.
  final String shortName;
  final String venue;
  final String district;
  final String category;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String price;
  final double latitude;
  final double longitude;
  final Uri? imageUrl;

  /// Photo crop: horizontal and vertical focus in percent, and zoom 1–3.
  final double imageX;
  final double imageY;
  final double imageZoom;
  final String markerLabel;
  final MarkerSize markerSize;
  final Color color;
  final String description;
  final List<String> tags;
  final Uri? sourceUrl;
  final Uri? ticketUrl;

  String get pinLabel => shortName.isNotEmpty ? shortName : name;

  /// The two characters drawn inside a pin without a photo.
  String get initials {
    final source = markerLabel.isNotEmpty ? markerLabel : name;
    return source.characters.take(2).toString().toUpperCase();
  }

  /// Alignment for `BoxFit.cover` matching CSS `object-position: X% Y%`.
  Alignment get imageAlignment => Alignment(imageX / 50 - 1, imageY / 50 - 1);

  /// Includes overnight events on each day they run; an end exactly at
  /// midnight is exclusive. Mirrors `eventOnDay` from the web app.
  bool occursOn(CalendarDay day) => firstDay <= day && day <= lastDay;

  CalendarDay get firstDay => CalendarDay.of(startsAt);

  CalendarDay get lastDay {
    final end = endsAt;
    return end != null ? CalendarDay.of(end.subtract(const Duration(milliseconds: 1))) : firstDay;
  }

  /// The first day of [range] this event runs on, or null if it misses it.
  CalendarDay? firstDayWithin(DayRange range) {
    final day = firstDay > range.first ? firstDay : range.first;
    return day <= lastDay && day <= range.last ? day : null;
  }

  bool isLiveAt(DateTime now) => !now.isBefore(startsAt) && now.isBefore(endsAt ?? startsAt.add(assumedDuration));

  @override
  bool operator ==(Object other) => other is Event && other.id == id && other.startsAt == startsAt;

  @override
  int get hashCode => Object.hash(id, startsAt);

  @override
  String toString() => 'Event($id, $name)';
}

/// Parses `#rrggbb`; returns null for anything else.
Color? parseHexColor(Object? value) {
  if (value is! String) return null;
  final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(value.trim());
  if (match == null) return null;
  return Color(0xFF000000 | int.parse(match.group(1)!, radix: 16));
}

String _string(Object? value) => value is String ? value.trim() : '';

double? _parseDouble(Object? value) => switch (value) {
  final num number when number.isFinite => number.toDouble(),
  final String text => double.tryParse(text),
  _ => null,
};

DateTime? _parseDate(Object? value) => value is String && value.isNotEmpty ? DateTime.tryParse(value)?.toUtc() : null;

/// Only http(s) links are allowed, like the web app's validation.
Uri? _resolveUrl(Object? value, Uri baseUri) {
  final text = _string(value);
  if (text.isEmpty) return null;
  final uri = Uri.tryParse(text);
  if (uri == null) return null;
  final resolved = uri.hasScheme ? uri : baseUri.resolveUri(uri);
  return resolved.isScheme('https') || resolved.isScheme('http') ? resolved : null;
}

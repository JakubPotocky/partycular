import 'dart:convert';

import 'package:partycular/data/event.dart';

final testBaseUri = Uri.parse('https://partycular.eu');

/// A JSON record shaped like `GET /api/events` returns.
Map<String, Object?> eventJson({
  int id = 1,
  String name = 'Techno pod hradom',
  String shortName = 'Techno',
  String venue = 'Subclub',
  String category = 'Párty',
  String startsAt = '2026-10-28T20:00:00.000Z',
  String endsAt = '',
  double latitude = 48.1407,
  double longitude = 17.1002,
  String imageUrl = '',
  String sourceUrl = '',
  String ticketUrl = '',
  String tags = '',
  String description = '',
}) => {
  'id': id,
  'sourceUrl': sourceUrl,
  'ticketUrl': ticketUrl,
  'name': name,
  'shortName': shortName,
  'venue': venue,
  'district': 'Staré Mesto',
  'category': category,
  'startsAt': startsAt,
  'endsAt': endsAt,
  'price': '12 €',
  'latitude': latitude,
  'longitude': longitude,
  'imageUrl': imageUrl,
  'imageX': 50,
  'imageY': 50,
  'imageZoom': 1,
  'markerLabel': 'SC',
  'markerSize': 'large',
  'color': '#c7ff2f',
  'description': description,
  'tags': tags,
  'status': 'published',
  'createdAt': '2026-09-01T00:00:00.000Z',
};

Event eventFixture({
  int id = 1,
  String name = 'Techno pod hradom',
  String category = 'Párty',
  String startsAt = '2026-10-28T20:00:00.000Z',
  String endsAt = '',
  double latitude = 48.1407,
  double longitude = 17.1002,
  String description = '',
  String sourceUrl = '',
  String ticketUrl = '',
}) => Event.fromJson(
  eventJson(
    id: id,
    name: name,
    category: category,
    startsAt: startsAt,
    endsAt: endsAt,
    latitude: latitude,
    longitude: longitude,
    description: description,
    sourceUrl: sourceUrl,
    ticketUrl: ticketUrl,
  ),
  baseUri: testBaseUri,
);

String eventsBody(List<Map<String, Object?>> records) => jsonEncode(records);

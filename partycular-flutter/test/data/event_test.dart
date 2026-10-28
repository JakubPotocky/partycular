import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partycular/core/time/calendar_day.dart';
import 'package:partycular/data/event.dart';

import '../support/fixtures.dart';

void main() {
  test('parses a full API record', () {
    final event = Event.fromJson(
      eventJson(tags: 'Bratislava, večer', ticketUrl: 'https://example.com/tickets'),
      baseUri: testBaseUri,
    );
    expect(event.id, 1);
    expect(event.startsAt, DateTime.utc(2026, 10, 28, 20));
    expect(event.endsAt, isNull);
    expect(event.markerSize, MarkerSize.large);
    expect(event.color, const Color(0xFFC7FF2F));
    expect(event.tags, ['Bratislava', 'večer']);
    expect(event.ticketUrl, Uri.parse('https://example.com/tickets'));
    expect(event.sourceUrl, isNull);
  });

  test('resolves uploaded images against the API host', () {
    final event = Event.fromJson(
      eventJson(imageUrl: '/api/images/8a97c41f-ba2e-4c46-8f33-670647570ab6'),
      baseUri: testBaseUri,
    );
    expect(event.imageUrl.toString(), 'https://partycular.eu/api/images/8a97c41f-ba2e-4c46-8f33-670647570ab6');
  });

  test('rejects non-http links', () {
    final event = Event.fromJson(eventJson(sourceUrl: 'javascript:alert(1)'), baseUri: testBaseUri);
    expect(event.sourceUrl, isNull);
  });

  test('falls back to safe defaults for odd values', () {
    final json = eventJson()
      ..['markerSize'] = 'giant'
      ..['color'] = 'red'
      ..['imageZoom'] = 9
      ..['imageX'] = null;
    final event = Event.fromJson(json, baseUri: testBaseUri);
    expect(event.markerSize, MarkerSize.medium);
    expect(event.color, Event.defaultColor);
    expect(event.imageZoom, 3);
    expect(event.imageX, 50);
  });

  test('drops an end time that is not after the start', () {
    final event = Event.fromJson(
      eventJson(startsAt: '2026-10-28T20:00:00Z', endsAt: '2026-10-28T19:00:00Z'),
      baseUri: testBaseUri,
    );
    expect(event.endsAt, isNull);
  });

  test('throws for records the map cannot place', () {
    final json = eventJson()..remove('latitude');
    expect(() => Event.fromJson(json, baseUri: testBaseUri), throwsFormatException);
  });

  test('builds initials safely from emoji labels', () {
    final json = eventJson()..['markerLabel'] = '🎃PRI';
    expect(Event.fromJson(json, baseUri: testBaseUri).initials, '🎃P');
  });

  test('maps the CSS crop focus to an alignment', () {
    final json = eventJson()
      ..['imageX'] = 0
      ..['imageY'] = 100;
    expect(Event.fromJson(json, baseUri: testBaseUri).imageAlignment, Alignment.bottomLeft);
  });

  test('is live from the start for its duration', () {
    final event = eventFixture(startsAt: '2026-10-28T20:00:00Z', endsAt: '2026-10-28T23:00:00Z');
    expect(event.isLiveAt(DateTime.utc(2026, 10, 28, 19, 59)), isFalse);
    expect(event.isLiveAt(DateTime.utc(2026, 10, 28, 20)), isTrue);
    expect(event.isLiveAt(DateTime.utc(2026, 10, 28, 23)), isFalse);
    final open = eventFixture(startsAt: '2026-10-28T20:00:00Z');
    expect(open.isLiveAt(DateTime.utc(2026, 10, 28, 23, 59)), isTrue);
    expect(open.isLiveAt(DateTime.utc(2026, 10, 29, 0, 1)), isFalse);
  });

  test('finds the first day of a range an event runs on', () {
    final range = DayRange(CalendarDay.parse('2026-10-30'), CalendarDay.parse('2026-11-01'));
    final thursdayAllNighter = eventFixture(startsAt: '2026-10-29T21:00:00Z', endsAt: '2026-10-30T05:00:00Z');
    final saturday = eventFixture(startsAt: '2026-10-31T19:00:00Z');
    final thursday = eventFixture(startsAt: '2026-10-29T19:00:00Z');
    final monday = eventFixture(startsAt: '2026-11-02T19:00:00Z');

    expect(thursdayAllNighter.firstDayWithin(range), CalendarDay.parse('2026-10-30'));
    expect(saturday.firstDayWithin(range), CalendarDay.parse('2026-10-31'));
    expect(thursday.firstDayWithin(range), isNull);
    expect(monday.firstDayWithin(range), isNull);
  });
}

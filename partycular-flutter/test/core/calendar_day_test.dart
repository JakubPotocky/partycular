import 'package:flutter_test/flutter_test.dart';
import 'package:partycular/core/time/calendar_day.dart';

import '../support/fixtures.dart';

void main() {
  group('bratislavaOffset', () {
    test('is +1 h in winter and +2 h in summer', () {
      expect(bratislavaOffset(DateTime.utc(2026, 1, 15, 12)), const Duration(hours: 1));
      expect(bratislavaOffset(DateTime.utc(2026, 7, 15, 12)), const Duration(hours: 2));
    });

    test('switches at 01:00 UTC on the last Sundays of March and October', () {
      // 2026: 29 March and 25 October.
      expect(bratislavaOffset(DateTime.utc(2026, 3, 29, 0, 59)), const Duration(hours: 1));
      expect(bratislavaOffset(DateTime.utc(2026, 3, 29, 1)), const Duration(hours: 2));
      expect(bratislavaOffset(DateTime.utc(2026, 10, 25, 0, 59)), const Duration(hours: 2));
      expect(bratislavaOffset(DateTime.utc(2026, 10, 25, 1)), const Duration(hours: 1));
    });
  });

  group('CalendarDay', () {
    // The same cases as the web app's tests/date-filter.mjs.
    test('uses the Bratislava date, not UTC', () {
      expect(CalendarDay.of(DateTime.parse('2026-09-22T22:30:00Z')).key, '2026-09-23');
    });

    test('adds days across month, year and DST boundaries', () {
      expect(CalendarDay.parse('2026-10-25').addDays(1).key, '2026-10-26');
      expect(CalendarDay.parse('2026-12-31').addDays(1).key, '2027-01-01');
      expect(CalendarDay.parse('2026-03-01').addDays(-1).key, '2026-02-28');
    });

    test('compares chronologically', () {
      final a = CalendarDay.parse('2026-09-30');
      final b = CalendarDay.parse('2026-10-01');
      expect(a < b, isTrue);
      expect(b >= a, isTrue);
      expect(a == CalendarDay.parse('2026-09-30'), isTrue);
    });

    test('knows month geometry', () {
      const october = CalendarDay(2026, 10, 1);
      expect(october.daysInMonth, 31);
      expect(october.weekday, DateTime.thursday);
      expect(october.addMonths(3).key, '2027-01-01');
    });
  });

  group('Event.occursOn', () {
    final overnight = eventFixture(startsAt: '2026-09-22T22:00:00+02:00', endsAt: '2026-09-23T03:00:00+02:00');

    test('includes every day an overnight event runs', () {
      expect(overnight.occursOn(CalendarDay.parse('2026-09-22')), isTrue);
      expect(overnight.occursOn(CalendarDay.parse('2026-09-23')), isTrue);
      expect(overnight.occursOn(CalendarDay.parse('2026-09-24')), isFalse);
    });

    test('treats an end exactly at midnight as exclusive', () {
      final event = eventFixture(startsAt: '2026-09-22T22:00:00+02:00', endsAt: '2026-09-23T00:00:00+02:00');
      expect(event.occursOn(CalendarDay.parse('2026-09-23')), isFalse);
    });

    test('uses only the start day when there is no end', () {
      final event = eventFixture(startsAt: '2026-09-22T22:00:00+02:00');
      expect(event.occursOn(CalendarDay.parse('2026-09-23')), isFalse);
    });

    test('handles the autumn DST change', () {
      final event = eventFixture(startsAt: '2026-10-25T01:30:00+02:00', endsAt: '2026-10-25T03:30:00+01:00');
      expect(event.occursOn(CalendarDay.parse('2026-10-25')), isTrue);
    });
  });
}

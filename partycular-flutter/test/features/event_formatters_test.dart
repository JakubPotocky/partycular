import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:partycular/core/strings.dart';
import 'package:partycular/core/time/calendar_day.dart';
import 'package:partycular/features/events/event_formatters.dart';

import '../support/fixtures.dart';

void main() {
  setUpAll(() => initializeDateFormatting('sk'));

  test('formats times in Bratislava time', () {
    // 20:00 UTC is 21:00 in winter time.
    expect(EventFormat.time(DateTime.utc(2026, 10, 28, 20)), '21:00');
    expect(EventFormat.time(DateTime.utc(2026, 7, 1, 20)), '22:00');
  });

  test('formats days in Slovak with genitive months', () {
    const day = CalendarDay(2026, 10, 28);
    expect(EventFormat.day(day), 'streda 28. októbra');
    expect(EventFormat.dayHeading(day), 'Streda, 28. októbra');
    expect(EventFormat.shortDay(day), '28. 10.');
    expect(EventFormat.month(day), 'október 2026');
  });

  test('formats a schedule with an overnight end', () {
    final event = eventFixture(startsAt: '2026-10-28T20:00:00Z', endsAt: '2026-10-29T02:00:00Z');
    expect(EventFormat.schedule(event), 'streda 28. októbra · 21:00 – 03:00');
  });

  test('includes the end date for multi-day events', () {
    final event = eventFixture(startsAt: '2026-10-28T16:00:00Z', endsAt: '2026-10-30T16:00:00Z');
    expect(EventFormat.schedule(event), 'streda 28. októbra · 17:00 – 30. októbra 17:00');
  });

  test('uses Slovak plural forms', () {
    expect(S.eventCount(0), '0 eventov');
    expect(S.eventCount(1), '1 event');
    expect(S.eventCount(3), '3 eventy');
    expect(S.eventCount(5), '5 eventov');
  });
}

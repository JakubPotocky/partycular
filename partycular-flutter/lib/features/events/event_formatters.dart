import 'package:intl/intl.dart';

import '../../core/time/calendar_day.dart';
import '../../data/event.dart';

/// Slovak, Bratislava-time formatting for events and days.
/// Requires `initializeDateFormatting('sk')` to have run.
abstract final class EventFormat {
  static const _locale = 'sk';

  /// `20:00`
  static String time(DateTime instant) => DateFormat('HH:mm', _locale).format(inBratislava(instant));

  /// `piatok 9. októbra`
  static String day(CalendarDay day) => DateFormat('EEEE d. MMMM', _locale).format(day.noon);

  /// `Piatok, 9. októbra` – for headings.
  static String dayHeading(CalendarDay day) {
    final text = DateFormat('EEEE, d. MMMM', _locale).format(day.noon);
    return text[0].toUpperCase() + text.substring(1);
  }

  /// `9. 10.` – compact, for the day picker pill.
  static String shortDay(CalendarDay day) => '${day.day}. ${day.month}.';

  /// `október 2026` – calendar title.
  static String month(CalendarDay day) => DateFormat('LLLL y', _locale).format(day.noon);

  /// `piatok 9. októbra · 20:00 – 03:00` with the end date when it differs.
  static String schedule(Event event) {
    final start = CalendarDay.of(event.startsAt);
    final buffer = StringBuffer('${day(start)} · ${time(event.startsAt)}');
    final end = event.endsAt;
    if (end != null) {
      final endDay = CalendarDay.of(end);
      final sameNight = endDay == start || (endDay == start.addDays(1) && inBratislava(end).hour < 12);
      buffer.write(
        sameNight ? ' – ${time(end)}' : ' – ${DateFormat('d. MMMM', _locale).format(inBratislava(end))} ${time(end)}',
      );
    }
    return buffer.toString();
  }
}

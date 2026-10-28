import 'package:flutter/foundation.dart';

/// UTC offset of Europe/Bratislava at [instant].
///
/// Slovakia follows the EU rule: CET (UTC+1), and CEST (UTC+2) from the last
/// Sunday of March to the last Sunday of October, switching at 01:00 UTC.
/// Computing it directly keeps calendar logic synchronous and identical on
/// every platform, without a time zone database.
Duration bratislavaOffset(DateTime instant) {
  final utc = instant.toUtc();
  final summerStart = _lastSundayAt1Utc(utc.year, DateTime.march);
  final summerEnd = _lastSundayAt1Utc(utc.year, DateTime.october);
  final isSummer = !utc.isBefore(summerStart) && utc.isBefore(summerEnd);
  return Duration(hours: isSummer ? 2 : 1);
}

DateTime _lastSundayAt1Utc(int year, int month) {
  final lastDay = DateTime.utc(year, month + 1, 0, 1);
  return lastDay.subtract(Duration(days: lastDay.weekday % DateTime.daysPerWeek));
}

/// Bratislava wall-clock time of [instant].
///
/// The result is flagged UTC but its fields (year … minute) are the local
/// Bratislava ones, which is what formatting and day keys need.
DateTime inBratislava(DateTime instant) {
  final utc = instant.toUtc();
  return utc.add(bratislavaOffset(utc));
}

/// A date on the Bratislava calendar, without time or zone.
@immutable
class CalendarDay implements Comparable<CalendarDay> {
  const CalendarDay(this.year, this.month, this.day);

  /// The Bratislava calendar day that contains [instant].
  factory CalendarDay.of(DateTime instant) {
    final local = inBratislava(instant);
    return CalendarDay(local.year, local.month, local.day);
  }

  /// Parses `yyyy-MM-dd`.
  factory CalendarDay.parse(String key) {
    final parts = key.split('-').map(int.parse).toList();
    if (parts.length != 3) throw FormatException('Invalid day key', key);
    return CalendarDay(parts[0], parts[1], parts[2]).normalized();
  }

  final int year;
  final int month;
  final int day;

  /// Day arithmetic in UTC, so DST transitions can never skip or repeat a day.
  CalendarDay addDays(int amount) {
    final date = DateTime.utc(year, month, day + amount);
    return CalendarDay(date.year, date.month, date.day);
  }

  CalendarDay normalized() => addDays(0);

  CalendarDay get firstOfMonth => CalendarDay(year, month, 1);

  CalendarDay addMonths(int amount) {
    final date = DateTime.utc(year, month + amount, 1);
    return CalendarDay(date.year, date.month, 1);
  }

  int get daysInMonth => DateTime.utc(year, month + 1, 0).day;

  /// 1 = Monday … 7 = Sunday.
  int get weekday => DateTime.utc(year, month, day).weekday;

  /// Noon of this day as a wall-clock value (see [inBratislava]), for
  /// formatting the date.
  DateTime get noon => DateTime.utc(year, month, day, 12);

  bool isSameMonth(CalendarDay other) => year == other.year && month == other.month;

  bool operator <(CalendarDay other) => compareTo(other) < 0;
  bool operator <=(CalendarDay other) => compareTo(other) <= 0;
  bool operator >(CalendarDay other) => compareTo(other) > 0;
  bool operator >=(CalendarDay other) => compareTo(other) >= 0;

  @override
  int compareTo(CalendarDay other) => _ordinal.compareTo(other._ordinal);

  int get _ordinal => year * 10000 + month * 100 + day;

  /// `yyyy-MM-dd`, matching the web app's day keys.
  String get key =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is CalendarDay && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => key;
}

/// An inclusive run of calendar days, e.g. a weekend.
@immutable
class DayRange {
  /// [last] must not be before [first].
  const DayRange(this.first, this.last);

  const DayRange.single(CalendarDay day) : first = day, last = day;

  final CalendarDay first;
  final CalendarDay last;

  bool get isSingleDay => first == last;

  bool contains(CalendarDay day) => first <= day && day <= last;

  /// Every day from [first] to [last].
  Iterable<CalendarDay> get days sync* {
    for (var day = first; day <= last; day = day.addDays(1)) {
      yield day;
    }
  }

  @override
  bool operator ==(Object other) => other is DayRange && other.first == first && other.last == last;

  @override
  int get hashCode => Object.hash(first, last);

  @override
  String toString() => isSingleDay ? first.key : '${first.key}..${last.key}';
}

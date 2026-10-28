import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/time/calendar_day.dart';
import '../../data/event.dart';
import 'events_controller.dart';

/// Categories in the order the admin offers them.
const knownCategories = ['Párty', 'Hudba', 'Kino', 'Kultúra', 'Gastro', 'Šport'];

/// Which days the map shows.
@immutable
sealed class DayFilter {
  const DayFilter();

  DayRange resolve(CalendarDay today);
}

final class TodayFilter extends DayFilter {
  const TodayFilter();

  @override
  DayRange resolve(CalendarDay today) => DayRange.single(today);
}

final class TomorrowFilter extends DayFilter {
  const TomorrowFilter();

  @override
  DayRange resolve(CalendarDay today) => DayRange.single(today.addDays(1));
}

/// Friday to Sunday of the current week. Once the weekend has begun it
/// starts today, so days already over are not shown.
final class WeekendFilter extends DayFilter {
  const WeekendFilter();

  @override
  DayRange resolve(CalendarDay today) {
    final friday = today.addDays(DateTime.friday - today.weekday);
    return DayRange(friday > today ? friday : today, friday.addDays(2));
  }
}

final class DateFilter extends DayFilter {
  const DateFilter(this.day);

  final CalendarDay day;

  @override
  DayRange resolve(CalendarDay today) => DayRange.single(day);

  @override
  bool operator ==(Object other) => other is DateFilter && other.day == day;

  @override
  int get hashCode => day.hashCode;
}

/// Today's Bratislava date, re-evaluated every minute so the filters roll
/// over at midnight while the app is open.
final todayProvider = NotifierProvider<TodayNotifier, CalendarDay>(TodayNotifier.new);

class TodayNotifier extends Notifier<CalendarDay> {
  @override
  CalendarDay build() {
    final now = ref.watch(clockProvider);
    final timer = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
    ref.onDispose(timer.cancel);
    return CalendarDay.of(now());
  }

  void refresh() => state = CalendarDay.of(ref.read(clockProvider)());
}

final dayFilterProvider = NotifierProvider<DayFilterNotifier, DayFilter>(DayFilterNotifier.new);

class DayFilterNotifier extends Notifier<DayFilter> {
  @override
  DayFilter build() => const TodayFilter();

  void select(DayFilter filter) => state = filter;

  /// Picks a calendar day, mapping today and tomorrow to their presets.
  void selectDay(CalendarDay day) {
    final today = ref.read(todayProvider);
    state = day == today
        ? const TodayFilter()
        : day == today.addDays(1)
        ? const TomorrowFilter()
        : DateFilter(day);
  }
}

/// The days the map shows: one, or several for the weekend.
final selectedRangeProvider = Provider<DayRange>(
  (ref) => ref.watch(dayFilterProvider).resolve(ref.watch(todayProvider)),
);

/// `null` means all categories.
final categoryFilterProvider = NotifierProvider<CategoryFilterNotifier, String?>(CategoryFilterNotifier.new);

class CategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? category) => state = category;
}

final allEventsProvider = Provider<List<Event>>((ref) => ref.watch(eventsProvider).value?.events ?? const []);

/// Categories that actually have events, in admin order.
final categoriesProvider = Provider<List<String>>((ref) {
  final present = ref.watch(allEventsProvider).map((e) => e.category).where((c) => c.isNotEmpty).toSet();
  return [
    ...knownCategories.where(present.contains),
    ...(present.difference(knownCategories.toSet()).toList()..sort()),
  ];
});

/// The chosen category, ignored once no event uses it any more.
final effectiveCategoryProvider = Provider<String?>((ref) {
  final category = ref.watch(categoryFilterProvider);
  return ref.watch(categoriesProvider).contains(category) ? category : null;
});

final categoryEventsProvider = Provider<List<Event>>((ref) {
  final category = ref.watch(effectiveCategoryProvider);
  final events = ref.watch(allEventsProvider);
  return category == null ? events : events.where((e) => e.category == category).toList(growable: false);
});

/// Events shown on the map: chosen days and category, sorted by start.
final visibleEventsProvider = Provider<List<Event>>((ref) {
  final range = ref.watch(selectedRangeProvider);
  return ref.watch(categoryEventsProvider).where((e) => e.firstDayWithin(range) != null).toList(growable: false);
});

/// The day each visible event is listed under (by id): the first shown day
/// it runs on. Groups the list and tags the pins when several days show.
final visibleEventDaysProvider = Provider<Map<int, CalendarDay>>((ref) {
  final range = ref.watch(selectedRangeProvider);
  return {for (final e in ref.watch(visibleEventsProvider)) e.id: e.firstDayWithin(range)!};
});

/// Every day that has at least one event, for the calendar dots.
final eventDaysProvider = Provider<Set<CalendarDay>>((ref) {
  const maxSpanDays = 31;
  final days = <CalendarDay>{};
  for (final event in ref.watch(categoryEventsProvider)) {
    var day = CalendarDay.of(event.startsAt);
    for (var i = 0; i < maxSpanDays && event.occursOn(day); i++) {
      days.add(day);
      day = day.addDays(1);
    }
  }
  return days;
});

/// The closest day after the selected ones that has events, if any; offered
/// when nothing is on.
final nextEventDayProvider = Provider<CalendarDay?>((ref) {
  final selected = ref.watch(selectedRangeProvider);
  final upcoming = ref.watch(eventDaysProvider).where((day) => day > selected.last).toList()..sort();
  return upcoming.firstOrNull;
});

final selectedEventIdProvider = NotifierProvider<SelectedEventNotifier, int?>(SelectedEventNotifier.new);

class SelectedEventNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int id) => state = id;

  void clear() => state = null;
}

/// The selected event, as long as it is still visible with current filters.
final selectedEventProvider = Provider<Event?>((ref) {
  final id = ref.watch(selectedEventIdProvider);
  if (id == null) return null;
  return ref.watch(visibleEventsProvider).where((e) => e.id == id).firstOrNull;
});

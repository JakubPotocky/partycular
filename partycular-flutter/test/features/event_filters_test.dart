import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:partycular/core/providers.dart';
import 'package:partycular/core/time/calendar_day.dart';
import 'package:partycular/data/event.dart';
import 'package:partycular/data/events_repository.dart';
import 'package:partycular/features/events/event_filters.dart';
import 'package:partycular/features/events/events_controller.dart';

import '../support/fixtures.dart';

class _MockRepository extends Mock implements EventsRepository {}

void main() {
  // Wednesday 28 October 2026, 10:00 in Bratislava.
  final now = DateTime.utc(2026, 10, 28, 9);
  final today = CalendarDay.of(now);

  late _MockRepository repository;

  Future<ProviderContainer> containerWith(List<Event> events) async {
    repository = _MockRepository();
    when(() => repository.load()).thenAnswer((_) async => EventsSnapshot(events: events, updatedAt: now));
    final container = ProviderContainer.test(
      overrides: [eventsRepositoryProvider.overrideWithValue(repository), clockProvider.overrideWithValue(() => now)],
      retry: (_, _) => null,
    );
    await container.read(eventsProvider.future);
    return container;
  }

  final todayParty = eventFixture(id: 1, startsAt: '2026-10-28T20:00:00Z');
  final todayConcert = eventFixture(id: 2, category: 'Hudba', startsAt: '2026-10-28T18:00:00Z');
  final tomorrowParty = eventFixture(id: 3, startsAt: '2026-10-29T20:00:00Z');
  final saturdayFilm = eventFixture(id: 4, category: 'Kino', startsAt: '2026-10-31T19:00:00Z');
  final all = [todayConcert, todayParty, tomorrowParty, saturdayFilm];

  test('shows today by default', () async {
    final container = await containerWith(all);
    expect(container.read(selectedRangeProvider), DayRange.single(today));
    expect(container.read(visibleEventsProvider), [todayConcert, todayParty]);
  });

  test('switches to tomorrow and to a picked date', () async {
    final container = await containerWith(all);
    final filter = container.read(dayFilterProvider.notifier);
    filter.select(const TomorrowFilter());
    expect(container.read(visibleEventsProvider), [tomorrowParty]);
    filter.selectDay(CalendarDay.parse('2026-10-31'));
    expect(container.read(dayFilterProvider), DateFilter(CalendarDay.parse('2026-10-31')));
    expect(container.read(visibleEventsProvider), [saturdayFilm]);
  });

  test('maps picked today and tomorrow to their presets', () async {
    final container = await containerWith(all);
    final filter = container.read(dayFilterProvider.notifier);
    filter.selectDay(today.addDays(1));
    expect(container.read(dayFilterProvider), isA<TomorrowFilter>());
    filter.selectDay(today);
    expect(container.read(dayFilterProvider), isA<TodayFilter>());
  });

  test('filters by category and lists only present categories in admin order', () async {
    final container = await containerWith(all);
    expect(container.read(categoriesProvider), ['Párty', 'Hudba', 'Kino']);
    container.read(categoryFilterProvider.notifier).select('Hudba');
    expect(container.read(visibleEventsProvider), [todayConcert]);
    expect(container.read(eventDaysProvider), {today});
  });

  test('ignores a category that no event has any more', () async {
    final container = await containerWith(all);
    container.read(categoryFilterProvider.notifier).select('Šport');
    expect(container.read(effectiveCategoryProvider), isNull);
    expect(container.read(visibleEventsProvider), hasLength(2));
  });

  test('marks every day with events and finds the next one', () async {
    final container = await containerWith(all);
    expect(container.read(eventDaysProvider), {today, today.addDays(1), CalendarDay.parse('2026-10-31')});
    container.read(dayFilterProvider.notifier).selectDay(CalendarDay.parse('2026-10-30'));
    expect(container.read(visibleEventsProvider), isEmpty);
    expect(container.read(nextEventDayProvider), CalendarDay.parse('2026-10-31'));
  });

  test('forgets the selection when the event is filtered out', () async {
    final container = await containerWith(all);
    container.read(selectedEventIdProvider.notifier).select(todayParty.id);
    expect(container.read(selectedEventProvider), todayParty);
    container.read(dayFilterProvider.notifier).select(const TomorrowFilter());
    expect(container.read(selectedEventProvider), isNull);
  });

  group('weekend', () {
    DayRange weekendOf(String day) => const WeekendFilter().resolve(CalendarDay.parse(day));

    test('is the coming Friday to Sunday on weekdays', () {
      final expected = DayRange(CalendarDay.parse('2026-10-30'), CalendarDay.parse('2026-11-01'));
      expect(weekendOf('2026-10-26'), expected); // Monday
      expect(weekendOf('2026-10-29'), expected); // Thursday
      expect(weekendOf('2026-10-30'), expected); // Friday
    });

    test('starts today once it has begun', () {
      expect(weekendOf('2026-10-31'), DayRange(CalendarDay.parse('2026-10-31'), CalendarDay.parse('2026-11-01')));
      expect(weekendOf('2026-11-01'), DayRange.single(CalendarDay.parse('2026-11-01')));
    });

    test('shows Friday to Sunday events, each under its first shown day', () async {
      final fridayNight = eventFixture(id: 5, startsAt: '2026-10-30T21:00:00Z', endsAt: '2026-10-31T03:00:00Z');
      final sundayBrunch = eventFixture(id: 6, startsAt: '2026-11-01T10:00:00Z');
      final mondayTalk = eventFixture(id: 7, startsAt: '2026-11-02T17:00:00Z');
      final container = await containerWith([...all.take(3), fridayNight, saturdayFilm, sundayBrunch, mondayTalk]);
      container.read(dayFilterProvider.notifier).select(const WeekendFilter());

      expect(container.read(visibleEventsProvider), [fridayNight, saturdayFilm, sundayBrunch]);
      expect(container.read(visibleEventDaysProvider), {
        5: CalendarDay.parse('2026-10-30'),
        4: CalendarDay.parse('2026-10-31'),
        6: CalendarDay.parse('2026-11-01'),
      });
      expect(container.read(nextEventDayProvider), CalendarDay.parse('2026-11-02'));
    });
  });
}

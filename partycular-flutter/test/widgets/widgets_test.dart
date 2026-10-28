import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:partycular/core/providers.dart';
import 'package:partycular/core/strings.dart';
import 'package:partycular/core/theme/app_theme.dart';
import 'package:partycular/core/time/calendar_day.dart';
import 'package:partycular/data/events_repository.dart';
import 'package:partycular/features/calendar/month_calendar.dart';
import 'package:partycular/features/event_detail/event_detail_card.dart';
import 'package:partycular/features/events/event_filters.dart';
import 'package:partycular/features/map/widgets/day_picker.dart';

import '../support/fixtures.dart';

class _MockRepository extends Mock implements EventsRepository {}

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.dark(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  setUpAll(() => initializeDateFormatting('sk'));

  group('MonthCalendar', () {
    testWidgets('marks days with events and reports the tapped day', (tester) async {
      CalendarDay? picked;
      await tester.pumpWidget(
        _app(
          MonthCalendar(
            selected: const DayRange.single(CalendarDay(2026, 10, 28)),
            today: const CalendarDay(2026, 10, 28),
            eventDays: {const CalendarDay(2026, 10, 9), const CalendarDay(2026, 10, 31)},
            onSelect: (day) => picked = day,
          ),
        ),
      );

      expect(find.text('Október 2026'), findsOneWidget);
      expect(find.text('Po'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^piatok 9\\. októbra, dni s eventami\$')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^sobota 10\\. októbra\$')), findsOneWidget);

      await tester.tap(find.text('31'));
      expect(picked, const CalendarDay(2026, 10, 31));
    });

    testWidgets('pages between months', (tester) async {
      await tester.pumpWidget(
        _app(
          MonthCalendar(
            selected: const DayRange.single(CalendarDay(2026, 12, 1)),
            today: const CalendarDay(2026, 12, 1),
            eventDays: const {},
            onSelect: (_) {},
          ),
        ),
      );
      await tester.tap(find.byTooltip(S.nextMonth));
      await tester.pump();
      expect(find.text('Január 2027'), findsOneWidget);
    });
  });

  group('EventDetailCard', () {
    testWidgets('shows details, links and toggles the description', (tester) async {
      var closed = false;
      final event = eventFixture(
        name: 'Noc v galérii',
        description: 'Program celej noci.',
        sourceUrl: 'https://example.com/event',
        ticketUrl: 'https://example.com/tickets',
      );
      await tester.pumpWidget(
        _app(EventDetailCard(event: event, now: DateTime.utc(2026, 10, 28, 9), onClose: () => closed = true)),
      );

      expect(find.text('Noc v galérii'), findsOneWidget);
      expect(find.text('streda 28. októbra · 21:00'), findsOneWidget);
      expect(find.text(S.tickets), findsOneWidget);
      expect(find.text(S.eventPage), findsOneWidget);
      expect(find.text('12 €'), findsOneWidget);
      expect(find.text(S.liveNow), findsNothing);

      expect(find.text('Program celej noci.'), findsNothing);
      await tester.tap(find.text(S.info));
      await tester.pumpAndSettle();
      expect(find.text('Program celej noci.'), findsOneWidget);

      await tester.tap(find.byTooltip(S.close));
      expect(closed, isTrue);
    });

    testWidgets('flags events happening now', (tester) async {
      final event = eventFixture(startsAt: '2026-10-28T20:00:00Z');
      await tester.pumpWidget(_app(EventDetailCard(event: event, now: DateTime.utc(2026, 10, 28, 21), onClose: () {})));
      expect(find.text(S.liveNow), findsOneWidget);
      expect(find.text(S.tickets), findsNothing);
    });
  });

  testWidgets('DayPicker switches the day filter', (tester) async {
    final repository = _MockRepository();
    when(repository.load).thenAnswer((_) async => EventsSnapshot(events: const [], updatedAt: DateTime(2026)));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventsRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 28, 9)),
        ],
        retry: (_, _) => null,
        child: _app(const SizedBox(width: 340, child: DayPicker())),
      ),
    );
    final container = ProviderScope.containerOf(tester.element(find.byType(DayPicker)));

    expect(container.read(dayFilterProvider), isA<TodayFilter>());
    await tester.tap(find.text(S.tomorrow));
    await tester.pump();
    expect(container.read(dayFilterProvider), isA<TomorrowFilter>());
    expect(container.read(selectedRangeProvider), const DayRange.single(CalendarDay(2026, 10, 29)));

    await tester.tap(find.text(S.weekend));
    await tester.pump();
    expect(container.read(dayFilterProvider), isA<WeekendFilter>());
    expect(container.read(selectedRangeProvider), const DayRange(CalendarDay(2026, 10, 30), CalendarDay(2026, 11, 1)));

    // Dispose the scope so the "today" ticker is cancelled before the test ends.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/time/calendar_day.dart';
import '../events/event_filters.dart';
import 'month_calendar.dart';

/// Shows the month calendar and returns the picked day, or null.
Future<CalendarDay?> showCalendarSheet(BuildContext context) => showModalBottomSheet<CalendarDay>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (_) => const CalendarSheet(),
);

class CalendarSheet extends ConsumerWidget {
  const CalendarSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppPalette.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MonthCalendar(
                selected: ref.watch(selectedRangeProvider),
                today: ref.watch(todayProvider),
                eventDays: ref.watch(eventDaysProvider),
                onSelect: (day) => Navigator.of(context).pop(day),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(S.daysWithEvents, style: TextStyle(color: p.muted, fontSize: 12.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

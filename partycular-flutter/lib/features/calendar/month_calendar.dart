import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/time/calendar_day.dart';
import '../events/event_formatters.dart';

/// A Monday-first month grid with dots under days that have events.
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.selected,
    required this.today,
    required this.eventDays,
    required this.onSelect,
  });

  /// Highlighted days: the picked day, or all of a weekend.
  final DayRange selected;
  final CalendarDay today;
  final Set<CalendarDay> eventDays;
  final ValueChanged<CalendarDay> onSelect;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late CalendarDay _month = widget.selected.first.firstOfMonth;

  void _showMonth(int delta) => setState(() => _month = _month.addMonths(delta));

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final title = EventFormat.month(_month);
    final leadingBlanks = _month.weekday - 1;
    final cells = leadingBlanks + _month.daysInMonth;
    final rows = (cells / 7).ceil();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() > 250) _showMonth(velocity < 0 ? 1 : -1);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title[0].toUpperCase() + title.substring(1),
                  style: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: S.previousMonth,
                onPressed: () => _showMonth(-1),
                icon: Icon(Icons.chevron_left_rounded, color: p.text),
              ),
              IconButton(
                tooltip: S.nextMonth,
                onPressed: () => _showMonth(1),
                icon: Icon(Icons.chevron_right_rounded, color: p.text),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final name in S.weekdaysShort)
                Expanded(
                  child: Center(
                    child: Text(
                      name,
                      style: TextStyle(color: p.muted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var row = 0; row < rows; row++)
            Row(
              children: [
                for (var column = 0; column < 7; column++) Expanded(child: _cell(row * 7 + column - leadingBlanks + 1)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(int dayNumber) {
    if (dayNumber < 1 || dayNumber > _month.daysInMonth) return const SizedBox(height: 46);
    final day = CalendarDay(_month.year, _month.month, dayNumber);
    return _DayCell(
      day: day,
      selected: widget.selected.contains(day),
      isToday: day == widget.today,
      hasEvents: widget.eventDays.contains(day),
      onTap: () => widget.onSelect(day),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.hasEvents,
    required this.onTap,
  });

  final CalendarDay day;
  final bool selected;
  final bool isToday;
  final bool hasEvents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final foreground = selected ? p.onAccent : p.text;
    return Semantics(
      button: true,
      selected: selected,
      label: '${EventFormat.day(day)}${hasEvents ? ', ${S.daysWithEvents.toLowerCase()}' : ''}',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          height: 46,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? p.accent : null,
                border: isToday && !selected ? Border.all(color: p.accent, width: 1.5) : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: foreground,
                      fontSize: 14,
                      fontWeight: selected || isToday ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                  if (hasEvents)
                    Positioned(
                      bottom: 5,
                      child: Container(
                        width: 4.5,
                        height: 4.5,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? p.onAccent : p.accent),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

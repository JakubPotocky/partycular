import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../ui/glass_panel.dart';
import '../../calendar/calendar_sheet.dart';
import '../../events/event_filters.dart';
import '../../events/event_formatters.dart';

/// The "Dnes / Zajtra / Kalendár" segmented pill.
class DayPicker extends ConsumerWidget {
  const DayPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(dayFilterProvider);
    final notifier = ref.read(dayFilterProvider.notifier);

    Future<void> openCalendar() async {
      final day = await showCalendarSheet(context);
      if (day != null) notifier.selectDay(day);
    }

    return GlassPanel(
      borderRadius: BorderRadius.circular(30),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _Segment(
              label: S.today,
              selected: filter is TodayFilter,
              onTap: () => notifier.select(const TodayFilter()),
            ),
          ),
          Expanded(
            flex: 2,
            child: _Segment(
              label: S.tomorrow,
              selected: filter is TomorrowFilter,
              onTap: () => notifier.select(const TomorrowFilter()),
            ),
          ),
          Expanded(
            flex: 3,
            child: _Segment(
              label: filter is DateFilter ? EventFormat.shortDay(filter.day) : S.calendar,
              semanticsLabel: filter is DateFilter ? '${S.calendar}: ${EventFormat.day(filter.day)}' : S.pickDate,
              icon: Icons.calendar_month_rounded,
              selected: filter is DateFilter,
              onTap: openCalendar,
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.onTap, this.icon, this.semanticsLabel});

  final String label;
  final String? semanticsLabel;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final foreground = selected ? p.onAccent : p.text;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel ?? label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? p.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 16, color: foreground), const SizedBox(width: 5)],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(color: foreground, fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/time/calendar_day.dart';
import '../../data/event.dart';
import '../../ui/event_image.dart';
import '../events/event_filters.dart';
import '../events/event_formatters.dart';
import '../events/events_controller.dart';

/// Lists [events] (by default the selected days') and returns the one the
/// user taps. [title] replaces the day heading, e.g. with a venue name.
Future<Event?> showEventListSheet(BuildContext context, {List<Event>? events, String? title}) =>
    showModalBottomSheet<Event>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollController) =>
            EventListSheet(scrollController: scrollController, events: events, title: title),
      ),
    );

class EventListSheet extends ConsumerWidget {
  const EventListSheet({super.key, this.scrollController, this.events, this.title});

  final ScrollController? scrollController;
  final List<Event>? events;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppPalette.of(context);
    final List<Event> items = events ?? ref.watch(visibleEventsProvider);
    final range = ref.watch(selectedRangeProvider);
    final eventDays = ref.watch(visibleEventDaysProvider);
    final now = ref.watch(clockProvider)();
    final rangeTitle = range.isSingleDay ? EventFormat.dayHeading(range.first) : S.thisWeekend;
    final subtitle = [
      if (title != null) rangeTitle,
      if (!range.isSingleDay) EventFormat.shortRange(range),
      S.eventCount(items.length),
    ].join(' · ');

    // Several days are listed in sections, one per day.
    final Iterable<({CalendarDay? day, List<Event> events})> groups = range.isSingleDay
        ? [(day: null, events: items)]
        : [
            for (final day in range.days)
              (
                day: day,
                events: [
                  for (final e in items)
                    if ((eventDays[e.id] ?? e.firstDay) == day) e,
                ],
              ),
          ].where((group) => group.events.isNotEmpty);

    return RefreshIndicator(
      onRefresh: () => ref.read(eventsProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? rangeTitle,
                    style: TextStyle(color: p.text, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.6),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: p.muted, fontSize: 13.5)),
                ],
              ),
            ),
          ),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy_rounded, size: 40, color: p.muted),
                      const SizedBox(height: 12),
                      Text(
                        range.isSingleDay ? S.emptyDay : S.emptyWeekend,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.muted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            for (final group in groups) ...[
              if (group.day case final day?) SliverToBoxAdapter(child: _DayHeader(day: day)),
              SliverList.separated(
                itemCount: group.events.length,
                separatorBuilder: (_, _) => Divider(indent: 84, endIndent: 20, color: p.border.withValues(alpha: 0.6)),
                itemBuilder: (context, index) => EventListTile(
                  event: group.events[index],
                  isLive: group.events[index].isLiveAt(now),
                  onTap: () => Navigator.of(context).pop(group.events[index]),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final CalendarDay day;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
        child: Text(
          EventFormat.dayHeading(day),
          style: TextStyle(color: p.accent, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.1),
        ),
      ),
    );
  }
}

class EventListTile extends StatelessWidget {
  const EventListTile({super.key, required this.event, required this.isLive, required this.onTap});

  final Event event;
  final bool isLive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final meta = [event.venue, if (event.price.isNotEmpty) event.price].where((s) => s.isNotEmpty).join(' · ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: event.color, width: 2),
              ),
              child: EventImage(event: event, size: 50),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        EventFormat.time(event.startsAt),
                        style: TextStyle(color: p.accent, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      if (isLive) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: p.live, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          S.liveNow,
                          style: TextStyle(color: p.live, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    event.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.text, fontSize: 15.5, fontWeight: FontWeight.w700, height: 1.25),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.muted, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.muted),
          ],
        ),
      ),
    );
  }
}

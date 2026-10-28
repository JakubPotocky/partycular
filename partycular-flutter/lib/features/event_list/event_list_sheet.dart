import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../data/event.dart';
import '../../ui/event_image.dart';
import '../events/event_filters.dart';
import '../events/event_formatters.dart';
import '../events/events_controller.dart';

/// Lists [events] (by default the selected day's) and returns the one the
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
    final day = ref.watch(selectedDayProvider);
    final now = ref.watch(clockProvider)();

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
                    title ?? EventFormat.dayHeading(day),
                    style: TextStyle(color: p.text, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.6),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title == null
                        ? S.eventCount(items.length)
                        : '${EventFormat.dayHeading(day)} · ${S.eventCount(items.length)}',
                    style: TextStyle(color: p.muted, fontSize: 13.5),
                  ),
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
                        S.emptyDay,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.muted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 24),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => Divider(indent: 84, endIndent: 20, color: p.border.withValues(alpha: 0.6)),
                itemBuilder: (context, index) => EventListTile(
                  event: items[index],
                  isLive: items[index].isLiveAt(now),
                  onTap: () => Navigator.of(context).pop(items[index]),
                ),
              ),
            ),
        ],
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

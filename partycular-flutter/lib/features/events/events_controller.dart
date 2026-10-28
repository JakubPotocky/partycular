import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/events_repository.dart';

/// All published events. Keeps showing the previous data while refreshing.
final eventsProvider = AsyncNotifierProvider<EventsController, EventsSnapshot>(EventsController.new);

class EventsController extends AsyncNotifier<EventsSnapshot> {
  @override
  Future<EventsSnapshot> build() => ref.watch(eventsRepositoryProvider).load();

  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // The error is exposed through `state`; callers only await completion.
    }
  }
}

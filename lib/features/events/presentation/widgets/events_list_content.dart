import 'package:flutter/widgets.dart';

import '../../domain/event.dart';
import 'event_list_tile.dart';

/// Lista de tarjetas de rodada, dentro de un `CustomScrollView` que ya
/// incluye los segmentos como header (ver `EventsListView`).
class EventsListContent extends StatelessWidget {
  const EventsListContent({
    required this.events,
    required this.onEventTap,
    super.key,
  });

  final List<Event> events;
  final ValueChanged<Event> onEventTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
      itemCount: events.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final event = events[index];
        return EventListTile(event: event, onTap: () => onEventTap(event));
      },
    );
  }
}

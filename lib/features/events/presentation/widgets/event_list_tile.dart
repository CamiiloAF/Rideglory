import 'package:flutter/widgets.dart';

import '../../../../design_system/components/event_card.dart';
import '../../domain/event.dart';
import '../event_labels.dart';

/// Adapta un [Event] de dominio al componente compartido [EventCard].
class EventListTile extends StatelessWidget {
  const EventListTile({required this.event, this.onTap, super.key});

  final Event event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return EventCard(
      name: event.name,
      dateLabel: eventDateLabel(event.startAt),
      destinationLabel: event.destinationName ?? '',
      difficultyLabel: eventDifficultyLabel(context, event.difficulty),
      priceLabel: eventPriceLabel(context, event.price),
      imageUrl: event.imageUrl,
      onTap: onTap,
    );
  }
}

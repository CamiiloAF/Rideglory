import 'package:flutter/material.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_header_placeholder.dart';

class EventDetailHeaderBackgroundImage extends StatelessWidget {
  const EventDetailHeaderBackgroundImage({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {
      return Image.network(
        event.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const EventDetailHeaderPlaceholder(),
      );
    }
    return const EventDetailHeaderPlaceholder();
  }
}

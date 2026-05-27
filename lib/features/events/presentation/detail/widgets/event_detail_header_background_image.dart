import 'package:flutter/material.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_image_placeholder.dart';

/// Full-bleed hero image for the Event Detail screen.
/// Matches Pencil page 5: h=219 image with no gradient overlay.
/// Falls back to a dark placeholder with a moto icon.
class EventDetailHeaderBackgroundImage extends StatelessWidget {
  const EventDetailHeaderBackgroundImage({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final imageUrl = event.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    if (hasImage) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const EventDetailImagePlaceholder(),
      );
    }
    return const EventDetailImagePlaceholder();
  }
}

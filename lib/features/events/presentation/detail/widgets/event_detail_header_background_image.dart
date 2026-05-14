import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

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
        errorBuilder: (_, _, _) => const _Placeholder(),
      );
    }
    return const _Placeholder();
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkCard,
      child: const Center(
        child: Icon(
          Icons.two_wheeler_rounded,
          color: AppColors.primary,
          size: 64,
        ),
      ),
    );
  }
}

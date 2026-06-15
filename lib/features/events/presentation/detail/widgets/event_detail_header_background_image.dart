import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_image_placeholder.dart';

class EventDetailHeaderBackgroundImage extends StatelessWidget {
  const EventDetailHeaderBackgroundImage({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final imageUrl = event.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    if (hasImage) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        fadeInDuration: const Duration(milliseconds: 400),
        fadeOutDuration: const Duration(milliseconds: 200),
        placeholder: (_, _) => const ColoredBox(color: AppColors.darkTertiary),
        errorWidget: (_, _, _) => const EventDetailImagePlaceholder(),
      );
    }
    return const EventDetailImagePlaceholder();
  }
}

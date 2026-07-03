import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/home/presentation/widgets/home_event_card_image_placeholder.dart';

class HomeEventCardImage extends StatelessWidget {
  const HomeEventCardImage({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          event.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: event.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const HomeEventCardImagePlaceholder(),
                  errorWidget: (_, _, _) =>
                      const HomeEventCardImagePlaceholder(),
                )
              : const HomeEventCardImagePlaceholder(),
          Positioned(
            top: 12,
            left: 12,
            child: AppEventBadge(
              label: event.state.label,
              variant: switch (event.state) {
                EventState.draft => EventBadgeVariant.comingSoon,
                EventState.scheduled => EventBadgeVariant.scheduled,
                EventState.inProgress => EventBadgeVariant.inProgress,
                EventState.finished => EventBadgeVariant.finished,
                EventState.cancelled => EventBadgeVariant.cancelled,
              },
            ),
          ),
        ],
      ),
    );
  }
}

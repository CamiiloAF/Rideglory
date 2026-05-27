import 'package:flutter/material.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_header_background_image.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_header_overlay_gradient.dart';

/// Image + gradient only; use inside [FlexibleSpaceBar] for collapsing app bar.
class EventDetailHeaderBackground extends StatelessWidget {
  const EventDetailHeaderBackground({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        EventDetailHeaderBackgroundImage(event: event),
        const EventDetailHeaderOverlayGradient(),
      ],
    );
  }
}

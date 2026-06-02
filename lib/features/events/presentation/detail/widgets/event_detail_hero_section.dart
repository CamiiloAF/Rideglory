import 'package:flutter/material.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_circle_button.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_header_background_image.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_options_bottom_sheet.dart';

/// Hero area: h=219 image + back button (top-left) + share button (top-right)
/// Optionally shows owner action menu.
class EventDetailHeroSection extends StatelessWidget {
  const EventDetailHeroSection({
    super.key,
    required this.event,
    required this.isOwner,
    required this.onBack,
    required this.onEdit,
    required this.onAttendees,
    required this.onDelete,
  });

  final EventModel event;
  final bool isOwner;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onAttendees;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 219 + topPadding,
      child: Stack(
        fit: StackFit.expand,
        children: [
          EventDetailHeaderBackgroundImage(event: event),
          // Back button — top-left
          Positioned(
            top: topPadding + 16,
            left: 16,
            child: EventDetailCircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
            ),
          ),
          // Owner actions menu — top-right (solo para el organizador)
          if (isOwner)
            Positioned(
              top: topPadding + 16,
              right: 16,
              child: EventDetailCircleButton(
                icon: Icons.more_vert,
                onTap: () => EventOptionsBottomSheet.show(
                  context: context,
                  eventName: event.name,
                  onEdit: onEdit,
                  onAttendees: onAttendees,
                  onDelete: onDelete,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

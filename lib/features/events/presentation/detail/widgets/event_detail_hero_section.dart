import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_circle_button.dart';
import 'package:rideglory/shared/widgets/fullscreen_image_viewer.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_header_background_image.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_options_bottom_sheet.dart';

/// Hero area: imagen full-bleed ~60% del viewport + gradientes + badge de estado
/// + botón atrás (top-left) + menú de owner (top-right).
/// Propuesta D — Pencil frame l2sJZ > nodo HwnXc.
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

  static double computeHeroHeight(BuildContext context) =>
      (MediaQuery.sizeOf(context).height * 0.65).clamp(430.0, 620.0);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final heroHeight = computeHeroHeight(context);

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: event.imageUrl != null && event.imageUrl!.isNotEmpty
                ? () => FullscreenImageViewer.show(
                    context,
                    imageUrl: event.imageUrl!,
                    heroTag: 'event-image-${event.id}',
                  )
                : null,
            child: Hero(
              tag: 'event-image-${event.id}',
              child: EventDetailHeaderBackgroundImage(event: event),
            ),
          ),

          // Gradiente superior (legibilidad del status bar)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x880D0D0F), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // Gradiente inferior (transición al card)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.darkBgPrimary,
                      AppColors.darkBgPrimary.withValues(alpha: 0.73),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.65, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Botón atrás — top-left
          Positioned(
            top: topPadding + 16,
            left: 16,
            child: EventDetailCircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
            ),
          ),

          // Menú de acciones del owner — top-right
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

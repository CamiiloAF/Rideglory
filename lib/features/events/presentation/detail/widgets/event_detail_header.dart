import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_overlay_button.dart';

class EventDetailHeader extends StatelessWidget {
  const EventDetailHeader({
    super.key,
    required this.event,
    required this.isOwner,
    required this.onBack,
    this.onEdit,
    this.onAttendees,
    this.onDelete,
  });

  final EventModel event;
  final bool isOwner;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onAttendees;
  final VoidCallback? onDelete;

  Color _typeColor(EventType type) => switch (type) {
    EventType.offRoad => const Color(0xFF8B4513),
    EventType.onRoad => AppColors.primary,
    EventType.exhibition => const Color(0xFF7C3AED),
    EventType.charitable => const Color(0xFF0891B2),
  };

  String _badgeLabel() {
    final now = DateTime.now();
    if (event.startDate.isAfter(now)) return 'Próximo evento';
    final end = event.endDate ?? event.startDate;
    if (event.startDate.isBefore(now) && end.isAfter(now)) return 'En curso';
    return event.eventType.label;
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(event.eventType);

    return SizedBox(
      height: 400,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  typeColor.withValues(alpha: 0.85),
                  const Color(0xFF0D1117),
                ],
              ),
            ),
          ),
          Positioned(
            right: -24,
            top: 30,
            child: Opacity(
              opacity: 0.07,
              child: const Icon(
                Icons.motorcycle,
                size: 260,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFF0D1117)],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      EventDetailOverlayButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onPressed: onBack,
                      ),
                      if (isOwner)
                        Row(
                          children: [
                            if (onAttendees != null)
                              EventDetailOverlayButton(
                                icon: Icons.people_outline,
                                onPressed: onAttendees!,
                              ),
                            if (onEdit != null)
                              EventDetailOverlayButton(
                                icon: Icons.edit_outlined,
                                onPressed: onEdit!,
                              ),
                            if (onDelete != null)
                              EventDetailOverlayButton(
                                icon: Icons.delete_outline,
                                onPressed: onDelete!,
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _badgeLabel().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.isFree
                          ? 'Gratis'
                          : '\$${_formatPrice(event.price!)} COP',
                      style: TextStyle(
                        color: event.isFree
                            ? Colors.greenAccent
                            : AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatPrice(int price) =>
      NumberFormat('#,###', 'es').format(price);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final bool isOwner;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('d MMM', 'es');
    final timeFormatter = DateFormat('hh:mm a');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 600,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowDark,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background with gradient
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Event background image (local asset with network fallback)
                  Image.asset('assets/images/event.jpeg', fit: BoxFit.cover),
                  // Dark overlay for better text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mi Evento badge (when user is owner)
            if (isOwner)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'MI EVENTO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Price/Gratis badge
            Positioned(
              top: isOwner ? 52 : 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: event.isFree
                      ? AppColors.eventFree
                      : AppColors.eventPaid,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowMedium,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  event.isFree
                      ? 'Gratis'
                      : '\$${event.price?.toStringAsFixed(0) ?? '0'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Brands/Type tags
            if (event.allowedBrands.isNotEmpty)
              Positioned(
                top: 12,
                left: 12,
                child: Wrap(
                  spacing: 6,
                  children: [
                    ...event.allowedBrands
                        .take(2)
                        .map(
                          (brand) => _buildTag(
                            brand.toUpperCase(),
                            AppColors.secondary,
                          ),
                        ),
                  ],
                ),
              ),

            // Event type badge (when no brands specified)
            if (event.allowedBrands.isEmpty)
              Positioned(
                top: 12,
                left: 12,
                child: _buildTag(
                  event.eventType.label.toUpperCase(),
                  _getEventTypeColor(event.eventType),
                ),
              ),

            // Bottom content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Event title
                    Text(
                      event.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.city} • ${event.meetingPoint}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Difficulty and Date/Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Difficulty
                        Expanded(
                          child: Text(
                            event.difficulty.label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ),

                        // Date and Time
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${dateFormatter.format(event.startDate)}, ${timeFormatter.format(event.meetingTime)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getEventTypeColor(EventType eventType) {
    switch (eventType) {
      case EventType.offRoad:
        return AppColors.eventOffRoad;
      case EventType.onRoad:
        return AppColors.eventOnRoad;
      case EventType.exhibition:
        return AppColors.eventExhibition;
      case EventType.charitable:
        return AppColors.eventCharitable;
    }
  }
}

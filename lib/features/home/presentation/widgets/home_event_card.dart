import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/home/presentation/widgets/home_event_default_background.dart';
import 'package:rideglory/features/home/presentation/widgets/home_event_difficulty_badge.dart';
import 'package:rideglory/features/home/presentation/widgets/home_event_gradient_overlay.dart';
import 'package:rideglory/features/home/presentation/widgets/home_event_view_details_button.dart';

class HomeEventCard extends StatelessWidget {
  const HomeEventCard({super.key, required this.event, required this.onTap});

  final EventModel event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, yyyy', 'es');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.darkSurface,
          border: Border.all(color: AppColors.darkBorder),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            event.imageUrl != null
                ? Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: event.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const HomeEventDefaultBackground(),
                      errorWidget: (_, _, _) =>
                          const HomeEventDefaultBackground(),
                    ),
                  )
                : const Positioned.fill(child: HomeEventDefaultBackground()),
            const Positioned.fill(child: HomeEventGradientOverlay()),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  HomeEventDifficultyBadge(difficulty: event.difficulty),
                  const SizedBox(height: 80),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 8),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(event.startDate),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const HomeEventViewDetailsButton(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

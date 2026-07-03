import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/home/presentation/widgets/home_event_card_content.dart';
import 'package:rideglory/features/home/presentation/widgets/home_event_card_image.dart';

class HomeEventCard extends StatelessWidget {
  const HomeEventCard({super.key, required this.event, required this.onTap});

  final EventModel event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeEventCardImage(event: event),
            Expanded(child: HomeEventCardContent(event: event)),
          ],
        ),
      ),
    );
  }
}

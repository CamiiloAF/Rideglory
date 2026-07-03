import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/home/presentation/widgets/home_event_view_details_button.dart';
// Note: uses HomeEventViewDetailsButton (existing shared widget) instead of local _ViewDetailsButton

class HomeEventCardContent extends StatelessWidget {
  const HomeEventCardContent({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.name,
            style: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 14,
                color: AppColors.textOnDarkSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                event.startDate.formattedDate,
                style: const TextStyle(
                  color: AppColors.textOnDarkSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                LucideIcons.flame,
                size: 14,
                color: AppColors.textOnDarkTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                event.difficulty.shortLabel,
                style: const TextStyle(
                  color: AppColors.textOnDarkTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const HomeEventViewDetailsButton(),
        ],
      ),
    );
  }
}

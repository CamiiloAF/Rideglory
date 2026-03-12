import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';

const Color _mapPlaceholderBackground = Color(0xFF1F2B3B);

class EventDetailMeetingPointSection extends StatelessWidget {
  const EventDetailMeetingPointSection({
    super.key,
    required this.location,
    this.onViewMap,
  });

  final String location;
  final VoidCallback? onViewMap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          EventStrings.meetingPointLabel,
          style: const TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 168,
                width: double.infinity,
                color: _mapPlaceholderBackground,
                child: Center(
                  child: Icon(
                    Icons.place,
                    color: AppColors.primary,
                    size: 56,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            EventStrings.meetingPointLabel,
                            style: const TextStyle(
                              color: AppColors.darkTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            location,
                            style: TextStyle(
                              color: AppColors.darkTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onViewMap != null) ...[
                      const SizedBox(width: 12),
                      Material(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: onViewMap,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  EventStrings.viewMap,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

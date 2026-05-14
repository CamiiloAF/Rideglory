import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Meeting-point card matching Pencil page 5 "Meeting Point Section":
/// - Section title 16/700 white
/// - Map Card: radius 12, bg #1E1E24
///   - Map placeholder area h=130
///   - Address row: address text (13/normal secondary) + orange "Ver mapa" pill
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
          context.l10n.event_meetingPointLabel,
          style: const TextStyle(
            color: AppColors.textOnDarkPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Map placeholder ──────────────────────────────────────
              Container(
                height: 130,
                width: double.infinity,
                color: AppColors.darkTertiary,
                child: const Center(
                  child: Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
              ),

              // ── Address row ─────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          color: AppColors.textOnDarkSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (onViewMap != null) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onViewMap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: AppColors.darkBgPrimary,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                context.l10n.event_viewMap,
                                style: const TextStyle(
                                  color: AppColors.darkBgPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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

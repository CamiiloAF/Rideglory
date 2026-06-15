import 'package:flutter/material.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class EventDetailAllowedBrandsSection extends StatelessWidget {
  const EventDetailAllowedBrandsSection({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final labels = event.isMultiBrand || event.allowedBrands.isEmpty
        ? [context.l10n.event_allBrandsChip]
        : event.allowedBrands;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.event_allowedBrandsTitle,
          style: const TextStyle(
            color: AppColors.textOnDarkPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Space Grotesk',
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: labels
              .map(
                (label) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.darkBorderPrimary,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textOnDarkPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Space Grotesk',
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

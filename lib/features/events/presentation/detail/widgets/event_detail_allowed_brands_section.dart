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
          style: TextStyle(
            color: context.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        AppSpacing.gapMd,
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: labels
              .map(
                (label) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: context.colorScheme.primary, width: 1.5),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: context.colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

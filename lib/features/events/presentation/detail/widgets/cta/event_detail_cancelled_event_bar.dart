import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// CANCELLED event state: grey badge + explanation.
class EventDetailCancelledEventBar extends StatelessWidget {
  const EventDetailCancelledEventBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.darkTertiary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.block_outlined,
                color: AppColors.textOnDarkTertiary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.event_eventCancelled,
                style: const TextStyle(
                  color: AppColors.textOnDarkTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.event_cancelledMessage,
          style: const TextStyle(
            color: AppColors.textOnDarkSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// REJECTED: red badge + explanation text.
class EventDetailRejectedBar extends StatelessWidget {
  const EventDetailRejectedBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.errorSubtle,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cancel_outlined,
                color: AppColors.error,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.event_registrationRejected,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.event_rejectedMessage,
          style: const TextStyle(
            color: AppColors.textOnDarkSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

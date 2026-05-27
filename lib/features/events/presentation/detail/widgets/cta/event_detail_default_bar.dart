import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

/// DEFAULT: price label (left) + orange "Inscribirme" button (right).
class EventDetailDefaultBar extends StatelessWidget {
  const EventDetailDefaultBar({
    super.key,
    required this.event,
    required this.onRegister,
  });

  final EventModel event;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Price column
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.event_totalParticipation,
              style: const TextStyle(
                color: AppColors.textOnDarkTertiary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              event.isFree
                  ? context.l10n.event_free
                  : '${(event.price ?? 0).toStringAsFixed(2)}€',
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(width: 12),

        Expanded(
          child: AppButton(
            label: context.l10n.event_registerMe,
            onPressed: onRegister,
            height: 48,
            style: AppButtonStyle.filled,
            variant: AppButtonVariant.primary,
            shape: AppButtonShape.pill,
          ),
        ),
      ],
    );
  }
}

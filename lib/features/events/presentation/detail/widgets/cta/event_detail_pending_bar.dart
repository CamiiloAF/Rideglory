import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';

/// PENDING: yellow badge + "Tu solicitud está en revisión" + "Cancelar" button.
class EventDetailPendingBar extends StatelessWidget {
  const EventDetailPendingBar({
    super.key,
    required this.registration,
    this.onCancel,
  });

  final EventRegistrationModel registration;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.warningSubtle,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_outlined,
                color: AppColors.warning,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.event_pendingBadgeSuffix,
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Message + cancel button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                context.l10n.event_requestUnderReview,
                style: const TextStyle(
                  color: AppColors.textOnDarkSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            if (onCancel != null) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onCancel,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.darkBorderLight),
                  ),
                  child: Text(
                    context.l10n.cancel,
                    style: const TextStyle(
                      color: AppColors.textOnDarkSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

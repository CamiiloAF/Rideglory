import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/event_registration/constants/registration_strings.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/model/registration_with_event.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

class InscriptionCard extends StatelessWidget {
  const InscriptionCard({
    super.key,
    required this.item,
    required this.onDetails,
    required this.onSecondaryAction,
  });

  final RegistrationWithEvent item;
  final VoidCallback onDetails;
  final VoidCallback? onSecondaryAction;

  static Color _statusBackgroundColor(RegistrationStatus status) {
    switch (status) {
      case RegistrationStatus.approved:
        return AppColors.success;
      case RegistrationStatus.pending:
      case RegistrationStatus.readyForEdit:
        return AppColors.warning;
      case RegistrationStatus.rejected:
        return AppColors.error;
      case RegistrationStatus.cancelled:
        return AppColors.darkTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final registration = item.registration;
    final event = item.event;
    final status = registration.status;

    final dateTime = event != null
        ? '${DateFormat('d MMM yyyy', 'es').format(event.startDate)} • ${DateFormat('hh:mm a', 'es').format(event.meetingTime)}'
        : registration.createdDate != null
            ? DateFormat('d MMM yyyy', 'es').format(registration.createdDate!)
            : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              event?.imageUrl ?? '',
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 88,
                height: 88,
                color: AppColors.darkSurfaceHighest,
                child: Icon(
                  Icons.event_outlined,
                  color: colorScheme.onSurfaceVariant,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        registration.eventName,
                        style: context.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _statusBackgroundColor(status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.label.toUpperCase(),
                        style: context.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (dateTime.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateTime,
                        style: context.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: RegistrationStrings.details,
                        icon: Icons.visibility_outlined,
                        variant: AppButtonVariant.outline,
                        onPressed: onDetails,
                        isFullWidth: true,
                        height: 36,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (onSecondaryAction != null)
                      Expanded(
                        child: _SecondaryActionButton(
                          status: status,
                          onPressed: onSecondaryAction!,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.status,
    required this.onPressed,
  });

  final RegistrationStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;
    AppButtonVariant variant;
    switch (status) {
      case RegistrationStatus.approved:
        label = RegistrationStrings.myRegistration;
        icon = Icons.check_circle_outline;
        variant = AppButtonVariant.primary;
        break;
      case RegistrationStatus.pending:
        label = RegistrationStrings.viewDetail;
        icon = Icons.visibility_outlined;
        variant = AppButtonVariant.outline;
        break;
      case RegistrationStatus.readyForEdit:
        label = EventStrings.edit;
        icon = Icons.edit_outlined;
        variant = AppButtonVariant.outline;
        break;
      case RegistrationStatus.rejected:
        label = RegistrationStrings.reason;
        icon = Icons.info_outline;
        variant = AppButtonVariant.outline;
        break;
      case RegistrationStatus.cancelled:
        label = RegistrationStrings.reRegister;
        icon = Icons.refresh;
        variant = AppButtonVariant.outline;
        break;
    }

    return AppButton(
      label: label,
      icon: icon,
      variant: variant,
      onPressed: onPressed,
      isFullWidth: true,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }
}

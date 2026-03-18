import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/model/registration_with_event.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class InscriptionCard extends StatelessWidget {
  const InscriptionCard({
    super.key,
    required this.item,
    required this.onDetails,
    required this.onSecondaryAction,
    required this.onTap,
  });

  final RegistrationWithEvent item;
  final VoidCallback onDetails;
  final VoidCallback? onSecondaryAction;
  final VoidCallback onTap;

  Color _statusBackgroundColor(
    BuildContext context,
    RegistrationStatus status,
  ) {
    switch (status) {
      case RegistrationStatus.approved:
        return context.appColors.success;
      case RegistrationStatus.pending:
      case RegistrationStatus.readyForEdit:
        return context.appColors.warning;
      case RegistrationStatus.rejected:
        return context.colorScheme.error;
      case RegistrationStatus.cancelled:
        return context.colorScheme.onSurfaceVariant;
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.colorScheme.outlineVariant),
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
                  color: context.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.event_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 32,
                  ),
                ),
              ),
            ),
            AppSpacing.hGapMd,
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
                      AppSpacing.hGapSm,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _statusBackgroundColor(context, status),
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
                    AppSpacing.gapXxs,
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        AppSpacing.hGapXxs,
                        Text(
                          dateTime,
                          style: context.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                  AppSpacing.gapSm,
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: context.l10n.registration_details,
                          icon: Icons.visibility_outlined,
                          variant: AppButtonVariant.primary,
                          style: AppButtonStyle.outlined,
                          onPressed: onDetails,
                          isFullWidth: true,
                          height: 36,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                      ),
                      AppSpacing.hGapSm,
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
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({required this.status, required this.onPressed});

  final RegistrationStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;
    AppButtonVariant variant;
    AppButtonStyle style = AppButtonStyle.filled;
    switch (status) {
      case RegistrationStatus.approved:
        label = context.l10n.registration_myRegistration;
        icon = Icons.check_circle_outline;
        variant = AppButtonVariant.primary;
        break;
      case RegistrationStatus.pending:
        label = context.l10n.registration_viewDetail;
        icon = Icons.visibility_outlined;
        variant = AppButtonVariant.primary;
        style = AppButtonStyle.outlined;
        break;
      case RegistrationStatus.readyForEdit:
        label = context.l10n.event_edit;
        icon = Icons.edit_outlined;
        variant = AppButtonVariant.primary;
        style = AppButtonStyle.outlined;
        break;
      case RegistrationStatus.rejected:
        label = context.l10n.registration_reason;
        icon = Icons.info_outline;
        variant = AppButtonVariant.primary;
        style = AppButtonStyle.outlined;
        break;
      case RegistrationStatus.cancelled:
        label = context.l10n.registration_reRegister;
        icon = Icons.refresh;
        variant = AppButtonVariant.primary;
        style = AppButtonStyle.outlined;
        break;
    }

    return AppButton(
      label: label,
      icon: icon,
      variant: variant,
      style: style,
      onPressed: onPressed,
      isFullWidth: true,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }
}

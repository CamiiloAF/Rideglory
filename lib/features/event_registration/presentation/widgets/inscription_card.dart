import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
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

  Color _statusBgColor(RegistrationStatus status) {
    switch (status) {
      case RegistrationStatus.approved:
        return AppColors.successSubtle;
      case RegistrationStatus.pending:
      case RegistrationStatus.readyForEdit:
        return AppColors.warningSubtle;
      case RegistrationStatus.rejected:
        return AppColors.errorSubtle;
      case RegistrationStatus.cancelled:
        return AppColors.darkTertiary;
    }
  }

  Color _statusFgColor(RegistrationStatus status) {
    switch (status) {
      case RegistrationStatus.approved:
        return AppColors.success;
      case RegistrationStatus.pending:
      case RegistrationStatus.readyForEdit:
        return AppColors.warning;
      case RegistrationStatus.rejected:
        return AppColors.error;
      case RegistrationStatus.cancelled:
        return AppColors.textOnDarkTertiary;
    }
  }

  String _statusLabel(BuildContext context, RegistrationStatus status) {
    switch (status) {
      case RegistrationStatus.approved:
        return context.l10n.registration_statusBadgeApproved;
      case RegistrationStatus.pending:
        return context.l10n.registration_statusBadgePending;
      case RegistrationStatus.readyForEdit:
        return context.l10n.registration_statusBadgeReadyForEdit;
      case RegistrationStatus.rejected:
        return context.l10n.registration_statusBadgeRejected;
      case RegistrationStatus.cancelled:
        return context.l10n.registration_statusBadgeCancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final registration = item.registration;
    final event = item.event;
    final status = registration.status;

    final dateLabel = event != null
        ? '${event.startDate.formattedDate} • ${event.meetingTime.formattedTime}'
        : registration.createdAt?.formattedDate ?? '';

    final fgColor = _statusFgColor(status);
    final bgColor = _statusBgColor(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorderPrimary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row: image + info + status badge
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          event?.imageUrl ?? '',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 72,
                            height: 72,
                            color: AppColors.darkTertiary,
                            child: const Icon(
                              Icons.event_outlined,
                              color: AppColors.textOnDarkTertiary,
                              size: 28,
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
                                    style: const TextStyle(
                                      color: AppColors.textOnDarkPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                AppSpacing.hGapSm,
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: fgColor.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    _statusLabel(context, status),
                                    style: TextStyle(
                                      color: fgColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (dateLabel.isNotEmpty) ...[
                              AppSpacing.gapXxs,
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 12,
                                    color: AppColors.textOnDarkSecondary,
                                  ),
                                  AppSpacing.hGapXxs,
                                  Expanded(
                                    child: Text(
                                      dateLabel,
                                      style: const TextStyle(
                                        color: AppColors.textOnDarkSecondary,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (event?.city != null) ...[
                              AppSpacing.gapXxs,
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 12,
                                    color: AppColors.textOnDarkSecondary,
                                  ),
                                  AppSpacing.hGapXxs,
                                  Expanded(
                                    child: Text(
                                      event!.city,
                                      style: const TextStyle(
                                        color: AppColors.textOnDarkSecondary,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider
                const Divider(
                  height: 1,
                  color: AppColors.darkBorderPrimary,
                ),
                // Action buttons row
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: context.l10n.registration_details,
                          icon: Icons.visibility_outlined,
                          variant: AppButtonVariant.primary,
                          style: AppButtonStyle.outlined,
                          onPressed: onDetails,
                          isFullWidth: true,
                          height: 38,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      if (onSecondaryAction != null) ...[
                        AppSpacing.hGapSm,
                        Expanded(
                          child: _SecondaryActionButton(
                            status: status,
                            onPressed: onSecondaryAction!,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
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
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:rideglory/core/utils/initials.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class AttendeeProcessedItem extends StatelessWidget {
  final EventRegistrationModel registration;
  final VoidCallback? onTap;
  final VoidCallback? onOptionsPressed;

  const AttendeeProcessedItem({
    super.key,
    required this.registration,
    this.onTap,
    this.onOptionsPressed,
  });

  static String _initials(EventRegistrationModel rider) {
    return Initials.buildFromFullName(rider.fullName);
  }

  static Color _avatarBackgroundColor(BuildContext context) {
    return context.colorScheme.surfaceContainerHighest;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final vehicleText =
        registration.vehicleSummary?.displayName.isNotEmpty == true
        ? registration.vehicleSummary!.displayName
        : context.l10n.notAvailable;
    final statusLabel = switch (registration.status) {
      RegistrationStatus.approved => context.l10n.event_approvedBadge,
      RegistrationStatus.cancelled =>
        context.l10n.registration_statusBadgeCancelled,
      _ => context.l10n.event_rejectedBadge,
    };
    final statusColor = switch (registration.status) {
      RegistrationStatus.approved => context.appColors.success,
      RegistrationStatus.cancelled => colorScheme.onSurfaceVariant,
      _ => colorScheme.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _avatarBackgroundColor(context),
                child: Text(
                  _initials(registration),
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      registration.fullName,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    AppSpacing.gapXxs,
                    Text(
                      vehicleText,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel,
                  style: textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                )
              else
                IconButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onOptionsPressed,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

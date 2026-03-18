import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

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

  static String _initials(EventRegistrationModel r) {
    final first = r.firstName.isNotEmpty ? r.firstName[0] : '';
    final last = r.lastName.isNotEmpty ? r.lastName[0] : '';
    return '${first.toUpperCase()}${last.toUpperCase()}';
  }

  static Color _avatarBackgroundColor(BuildContext context) {
    return context.colorScheme.surfaceContainerHighest;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final vehicleText =
        '${registration.vehicleBrand} ${registration.vehicleReference}';
    final isApproved =
        registration.status == RegistrationStatus.approved;
    final statusLabel = isApproved
        ? context.l10n.event_approvedBadge
        : context.l10n.event_rejectedBadge;
    final statusColor =
        isApproved ? context.appColors.success : colorScheme.error;

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
              SizedBox(width: 12),
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
                    SizedBox(height: 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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

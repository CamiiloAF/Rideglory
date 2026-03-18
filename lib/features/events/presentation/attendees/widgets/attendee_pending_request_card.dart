import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/attendees/attendees_cubit.dart';
import 'package:rideglory/features/events/presentation/attendees/attendee_action_confirmation.dart';
import 'package:rideglory/features/events/presentation/shared/widgets/initials_avatar.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class AttendeePendingRequestCard extends StatelessWidget {
  final EventRegistrationModel registration;
  final VoidCallback? onTap;

  const AttendeePendingRequestCard({
    super.key,
    required this.registration,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final vehicleText =
        '${registration.vehicleBrand} ${registration.vehicleReference}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InitialsAvatar(
                    firstName: registration.firstName,
                    lastName: registration.lastName,
                    radius: 24,
                    backgroundColor: colorScheme.primary,
                    textStyle: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          registration.fullName,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.two_wheeler_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                vehicleText,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    (() {
                      final createdDate = registration.createdDate;
                      if (createdDate == null) return '';
                      final now = DateTime.now();
                      final diff = now.difference(createdDate);
                      if (diff.inDays > 0) {
                        return context.l10n.event_timeAgoDays(
                          diff.inDays,
                        );
                      }
                      if (diff.inHours > 0) {
                        return context.l10n.event_timeAgoHours(
                          diff.inHours,
                        );
                      }
                      return context.l10n.event_timeAgoMinutes(
                        diff.inMinutes.clamp(0, 59),
                      );
                    })(),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          ApproveRejectBar(
            rejectLabel: context.l10n.event_rejectRegistration,
            approveLabel: context.l10n.event_approveRegistration,
            onReject: () => AttendeeActionConfirmation.showReject(
              context,
              firstName: registration.firstName,
              onConfirm: () => context
                  .read<AttendeesCubit>()
                  .rejectRegistration(registration.id!),
            ),
            onApprove: () => AttendeeActionConfirmation.showApprove(
              context,
              firstName: registration.firstName,
              onConfirm: () => context
                  .read<AttendeesCubit>()
                  .approveRegistration(registration.id!),
            ),
          ),
        ],
      ),
    );
  }
}

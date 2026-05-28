import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_participant_status_pill.dart';
import 'package:rideglory/features/events/presentation/shared/widgets/initials_avatar.dart';

class EventDetailParticipantRow extends StatelessWidget {
  const EventDetailParticipantRow({
    super.key,
    required this.registration,
    required this.borderRadius,
    this.onTap,
  });

  final EventRegistrationModel registration;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  String _joinedAgo(BuildContext context) {
    final createdAt = registration.createdAt;
    if (createdAt == null) return context.l10n.event_attendee_joinedRecently;
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) {
      return context.l10n.event_attendee_joinedDaysAgo(diff.inDays);
    }
    if (diff.inHours > 0) {
      return context.l10n.event_attendee_joinedHoursAgo(diff.inHours);
    }
    if (diff.inMinutes > 0) {
      return context.l10n.event_attendee_joinedMinutesAgo(diff.inMinutes);
    }
    return context.l10n.event_attendee_joinedRecently;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkCard,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              InitialsAvatar(
                fullName: registration.fullName,
                radius: 18,
                backgroundColor: AppColors.primarySubtle,
                textStyle: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      registration.fullName,
                      style: const TextStyle(
                        color: AppColors.textOnDarkPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _joinedAgo(context),
                      style: const TextStyle(
                        color: AppColors.textOnDarkTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              EventDetailParticipantStatusPill(status: registration.status),
            ],
          ),
        ),
      ),
    );
  }
}

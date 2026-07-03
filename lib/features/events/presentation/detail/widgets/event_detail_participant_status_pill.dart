import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';

class EventDetailParticipantStatusPill extends StatelessWidget {
  const EventDetailParticipantStatusPill({super.key, required this.status});

  final RegistrationStatus status;

  Color _color(BuildContext context) => switch (status) {
    RegistrationStatus.approved => context.appColors.success,
    RegistrationStatus.pending ||
    RegistrationStatus.readyForEdit => context.appColors.warning,
    RegistrationStatus.rejected => context.colorScheme.error,
    RegistrationStatus.cancelled => context.colorScheme.onSurfaceVariant,
  };

  IconData _icon() => switch (status) {
    RegistrationStatus.approved => Icons.check_circle_outline,
    RegistrationStatus.pending ||
    RegistrationStatus.readyForEdit => Icons.timer_outlined,
    RegistrationStatus.rejected => Icons.cancel_outlined,
    RegistrationStatus.cancelled => Icons.do_not_disturb_alt_outlined,
  };

  String _label(BuildContext context) => switch (status) {
    RegistrationStatus.approved =>
      context.l10n.registration_statusBadgeApproved,
    RegistrationStatus.pending => context.l10n.registration_statusBadgePending,
    RegistrationStatus.rejected =>
      context.l10n.registration_statusBadgeRejected,
    RegistrationStatus.cancelled =>
      context.l10n.registration_statusBadgeCancelled,
    RegistrationStatus.readyForEdit =>
      context.l10n.registration_statusBadgeReadyForEdit,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _label(context),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

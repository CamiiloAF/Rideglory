import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';

/// Píldora de estado de inscripción (fondo sutil + texto coloreado en
/// mayúsculas). Corresponde al nodo `statusPill` del diseño Pencil `y1Ci1`.
class RegistrationStatusPill extends StatelessWidget {
  const RegistrationStatusPill({super.key, required this.status});

  final RegistrationStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color foreground, String label) = switch (status) {
      RegistrationStatus.pending => (
        AppColors.warning,
        context.l10n.registration_statusBadgePending,
      ),
      RegistrationStatus.readyForEdit => (
        AppColors.info,
        context.l10n.registration_statusBadgeReadyForEdit,
      ),
      RegistrationStatus.approved => (
        AppColors.statusGreen,
        context.l10n.registration_statusBadgeApproved,
      ),
      RegistrationStatus.rejected => (
        AppColors.error,
        context.l10n.registration_statusBadgeRejected,
      ),
      RegistrationStatus.cancelled => (
        AppColors.textOnDarkSecondary,
        context.l10n.registration_statusBadgeCancelled,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

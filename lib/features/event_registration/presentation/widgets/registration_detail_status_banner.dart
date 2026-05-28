import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';

/// Banner de estado mostrado al piloto en su propia inscripción.
/// Corresponde al nodo `statusBanner` (bHPyC) del diseño Pencil `f0lXw`.
/// Devuelve [SizedBox.shrink] para estados que no requieren banner (aprobada).
class RegistrationDetailStatusBanner extends StatelessWidget {
  const RegistrationDetailStatusBanner({super.key, required this.status});

  final RegistrationStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color? color, IconData? icon, String? text) = switch (status) {
      RegistrationStatus.pending => (
        AppColors.warning,
        Icons.access_time_rounded,
        context.l10n.registration_pendingBannerText,
      ),
      RegistrationStatus.readyForEdit => (
        AppColors.info,
        Icons.edit_outlined,
        context.l10n.registration_readyForEditBannerText,
      ),
      RegistrationStatus.rejected => (
        AppColors.error,
        Icons.cancel_outlined,
        context.l10n.registration_rejectedBannerText,
      ),
      _ => (null, null, null),
    };

    if (color == null || icon == null || text == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.33)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

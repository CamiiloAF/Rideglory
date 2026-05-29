import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_status_pill.dart';
import 'package:rideglory/features/events/presentation/shared/widgets/initials_avatar.dart';

/// Banda de resumen del piloto en el detalle de inscripción (vista organizador).
/// Corresponde al nodo `Rider Summary` (aM5uW) del diseño Pencil `y1Ci1`.
class RegistrationDetailRiderSummary extends StatelessWidget {
  const RegistrationDetailRiderSummary({
    super.key,
    required this.registration,
    this.onTap,
  });

  final EventRegistrationModel registration;

  /// Cuando se provee (vista organizador), tocar la banda abre el perfil del
  /// piloto.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final createdAt = registration.createdAt;
    final meta = createdAt != null
        ? '${context.l10n.registration_appliedOnPrefix}${createdAt.formattedDate}'
        : '';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.darkCard,
          border: Border(
            bottom: BorderSide(color: AppColors.darkBorderPrimary),
          ),
        ),
        child: Row(
        children: [
          InitialsAvatar(
            fullName: registration.fullName,
            radius: 20,
            backgroundColor: AppColors.darkTertiary,
            textStyle: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
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
                  style: const TextStyle(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  AppSpacing.gapXxs,
                  Text(
                    meta,
                    style: const TextStyle(
                      color: AppColors.textOnDarkTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.hGapMd,
          RegistrationStatusPill(status: registration.status),
          if (onTap != null) ...[
            AppSpacing.hGapSm,
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textOnDarkTertiary,
            ),
          ],
        ],
        ),
      ),
    );
  }
}

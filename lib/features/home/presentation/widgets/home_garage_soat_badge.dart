import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

/// SOAT status badge shown on the garage card.
class HomeGarageSoatBadge extends StatelessWidget {
  const HomeGarageSoatBadge({super.key, required this.vehicle});

  final VehicleModel vehicle;

  Color _badgeBg() {
    return switch (vehicle.soatStatus) {
      SoatStatus.valid => AppColors.successSubtle,
      SoatStatus.expiringSoon => AppColors.warningSubtle,
      SoatStatus.expired => AppColors.errorSubtle,
      SoatStatus.noSoat || null => AppColors.infoSubtle,
    };
  }

  Color _badgeText() {
    return switch (vehicle.soatStatus) {
      SoatStatus.valid => AppColors.success,
      SoatStatus.expiringSoon => AppColors.warning,
      SoatStatus.expired => AppColors.error,
      SoatStatus.noSoat || null => AppColors.info,
    };
  }

  String _statusLabel(BuildContext context) {
    return switch (vehicle.soatStatus) {
      SoatStatus.valid => context.l10n.vehicle_doc_soat_label,
      SoatStatus.expiringSoon => context.l10n.vehicle_doc_soat_label,
      SoatStatus.expired => context.l10n.vehicle_doc_soat_label,
      SoatStatus.noSoat || null => context.l10n.vehicle_doc_soat_label,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _badgeBg(),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined, size: 12, color: _badgeText()),
              const SizedBox(width: 4),
              Text(
                _statusLabel(context),
                style: TextStyle(
                  color: _badgeText(),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

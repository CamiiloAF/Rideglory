import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class SoatVehicleInfoCard extends StatelessWidget {
  const SoatVehicleInfoCard({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.two_wheeler_rounded,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.name,
                  style: const TextStyle(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _vehicleSubtitle,
                  style: const TextStyle(
                    color: AppColors.textOnDarkSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (vehicle.soatStatus != null) _SoatStatusBadge(vehicle.soatStatus!),
        ],
      ),
    );
  }

  String get _vehicleSubtitle {
    final parts = <String>[];
    if (vehicle.year != null) parts.add(vehicle.year.toString());
    if (vehicle.licensePlate != null) parts.add(vehicle.licensePlate!);
    return parts.join(' · ');
  }
}

class _SoatStatusBadge extends StatelessWidget {
  const _SoatStatusBadge(this.status);

  final SoatStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _bgColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color get _bgColor {
    switch (status) {
      case SoatStatus.valid:
        return const Color(0xFF22C55E);
      case SoatStatus.expiringSoon:
        return const Color(0xFFEAB308);
      case SoatStatus.expired:
        return AppColors.error;
      case SoatStatus.noSoat:
        return AppColors.textOnDarkSecondary;
    }
  }

  String get _label {
    switch (status) {
      case SoatStatus.valid:
        return 'Vigente';
      case SoatStatus.expiringSoon:
        return 'Por vencer';
      case SoatStatus.expired:
        return 'Vencido';
      case SoatStatus.noSoat:
        return 'Sin SOAT';
    }
  }
}

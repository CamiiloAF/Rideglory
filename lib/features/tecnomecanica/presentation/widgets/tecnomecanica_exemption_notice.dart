import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

/// Non-blocking info chip shown when the vehicle might be exempt from RTM
/// (vehicles less than 2 years old). Does NOT block saving — purely visual.
class TecnomecanicaExemptionNotice extends StatelessWidget {
  const TecnomecanicaExemptionNotice({super.key, required this.vehicle});

  final VehicleModel vehicle;

  bool get _isExempt {
    final purchase = vehicle.purchaseDate;
    if (purchase != null) {
      return DateTime.now().difference(purchase).inDays < 730;
    }
    final year = vehicle.year;
    if (year != null) {
      return DateTime.now().year - year < 2;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isExempt) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.tecnomecanica_exemption_notice,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

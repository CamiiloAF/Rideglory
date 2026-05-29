import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/mileage_info_dialog.dart';

class InfoChipTooltip extends StatelessWidget {
  const InfoChipTooltip({
    super.key,
    required this.typeColor,
    required this.currentMileage,
    required this.maintenance,
  });

  final Color typeColor;
  final int? currentMileage;
  final MaintenanceModel maintenance;

  void _showMileageDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.darkBgPrimary.withValues(alpha: 0.82),
      builder: (dialogContext) => MileageInfoDialog(
        typeColor: typeColor,
        currentMileage: currentMileage,
        distanceUnitLabel: dialogContext.l10n.maintenance_km,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.l10n.maintenance_currentMileage,
      preferBelow: false,
      child: Material(
        color: Colors
            .transparent, // Intentional: Material requires transparent color to show InkWell splash correctly
        child: InkWell(
          onTap: () => _showMileageDialog(context),
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: .1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: typeColor.withValues(alpha: .2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.info_rounded, color: typeColor, size: 16),
          ),
        ),
      ),
    );
  }
}

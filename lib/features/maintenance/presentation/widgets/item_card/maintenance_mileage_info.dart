import 'package:flutter/material.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/info_chip_tooltip.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/maintenance_progress_bar.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class MaintenanceMileageInfo extends StatelessWidget {
  final MaintenanceModel maintenance;
  final Color typeColor;
  final int? currentMileage;
  final double? progressPercent;
  final int? Function(int?) getRemainingDistance;

  const MaintenanceMileageInfo({
    super.key,
    required this.maintenance,
    required this.typeColor,
    required this.currentMileage,
    required this.progressPercent,
    required this.getRemainingDistance,
  });

  @override
  Widget build(BuildContext context) {
    final remainingDistance = getRemainingDistance(currentMileage);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withValues(alpha: .1), width: 1),
      ),
      child: Column(
        children: [
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InfoChip(
                icon: Icons.build_rounded,
                label: context.l10n.maintenance_maintenance,
                value: maintenance.maintanceMileage.toStringAsFixed(0),
                color: const Color(0xFF64748B),
              ),
              if (maintenance.nextMaintenanceMileage != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InfoChip(
                      icon: Icons.flag_rounded,
                      label: context.l10n.maintenance_next,
                      value:
                          maintenance.nextMaintenanceMileage!.toStringAsFixed(0),
                      color: typeColor,
                      tooltip: InfoChipTooltip(
                        typeColor: typeColor,
                        currentMileage: currentMileage,
                        maintenance: maintenance,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (progressPercent != null) ...[
            SizedBox(height: 12),
            MaintenanceProgressBar(
              typeColor: typeColor,
              progressPercent: progressPercent!,
            ),
            SizedBox(height: 8),
            Text(
              remainingDistance != null
                  ? context.l10n.maintenance_remainingDistance(
                      remainingDistance.toStringAsFixed(0),
                      'km', // TODO: Add distance unit
                    )
                  : context.l10n.maintenance_calculateRemainingDistance,
              style: context.labelSmall?.copyWith(
                color: remainingDistance != null && remainingDistance <= 0
                    ? const Color(0xFFEF4444)
                    : null,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

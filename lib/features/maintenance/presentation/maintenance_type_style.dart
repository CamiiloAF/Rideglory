import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

abstract class MaintenanceTypeStyle {
  static Color color(MaintenanceType type) => switch (type) {
        MaintenanceType.oilChange => AppColors.primary,
        MaintenanceType.brakeCheck => AppColors.statusWarning,
        MaintenanceType.tireChange => AppColors.info,
        MaintenanceType.preventive => AppColors.statusGreen,
        MaintenanceType.airFilter => AppColors.eventShortDistance,
        MaintenanceType.chainSprocket => AppColors.textOnDarkTertiary,
        MaintenanceType.electrical => AppColors.warningLight,
        MaintenanceType.other => AppColors.darkTertiary,
      };

  static IconData icon(MaintenanceType type) => switch (type) {
        MaintenanceType.oilChange => Icons.opacity,
        MaintenanceType.brakeCheck => Icons.album_outlined,
        MaintenanceType.tireChange => Icons.radio_button_unchecked,
        MaintenanceType.preventive => Icons.assignment_turned_in_outlined,
        MaintenanceType.airFilter => Icons.air,
        MaintenanceType.chainSprocket => Icons.link,
        MaintenanceType.electrical => Icons.bolt,
        MaintenanceType.other => Icons.more_horiz,
      };
}

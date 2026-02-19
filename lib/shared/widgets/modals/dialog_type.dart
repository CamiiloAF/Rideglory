import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';

enum DialogType {
  confirmation,
  information,
  warning,
  success,
  error;

  const DialogType();

  IconData get icon {
    switch (this) {
      case DialogType.confirmation:
        return Icons.info_outline_rounded;
      case DialogType.information:
        return Icons.info_outline_rounded;
      case DialogType.warning:
        return Icons.warning_amber_rounded;
      case DialogType.success:
        return Icons.check_circle_outline_rounded;
      case DialogType.error:
        return Icons.error_outline_rounded;
    }
  }

  Color get color {
    switch (this) {
      case DialogType.confirmation:
        return AppColors.info;
      case DialogType.information:
        return AppColors.info;
      case DialogType.warning:
        return AppColors.warning;
      case DialogType.success:
        return AppColors.success;
      case DialogType.error:
        return AppColors.error;
    }
  }
}

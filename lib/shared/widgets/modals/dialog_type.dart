import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors_extension.dart';

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
    final palette = AppColorsExtension.rideglory();
    switch (this) {
      case DialogType.confirmation:
        return palette.info;
      case DialogType.information:
        return palette.info;
      case DialogType.warning:
        return palette.warning;
      case DialogType.success:
        return palette.success;
      case DialogType.error:
        return palette.error;
    }
  }
}

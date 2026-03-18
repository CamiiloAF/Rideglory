import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme extension to expose domain/status colors in a type-safe way.
///
/// Prefer using `ColorScheme` for semantic UI colors (primary/onSurface/etc).
/// This extension is for colors that don't map cleanly to Material semantics.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color success;
  final Color successLight;
  final Color warning;
  final Color warningLight;
  final Color info;
  final Color infoLight;
  final Color error;
  final Color errorLight;

  // Domain / event
  final Color eventOffRoad;
  final Color eventOnRoad;
  final Color eventExhibition;
  final Color eventCharitable;
  final Color eventFree;
  final Color eventPaid;
  final Color motorcycle;
  final Color car;
  final Color difficultyChip;

  // Maintenance
  final Color maintenanceUrgent;
  final Color maintenanceWarning;
  final Color maintenanceOk;

  // Misc
  final Color licensePlateTagBackground;
  final Color licensePlateTagText;
  final Color inputIcon;

  // Gradient / overlays
  final List<Color> primaryGradient;
  final Color overlayLight;
  final Color overlayMedium;
  final Color shadowLight;
  final Color shadowMedium;

  const AppColorsExtension({
    required this.success,
    required this.successLight,
    required this.warning,
    required this.warningLight,
    required this.info,
    required this.infoLight,
    required this.error,
    required this.errorLight,
    required this.eventOffRoad,
    required this.eventOnRoad,
    required this.eventExhibition,
    required this.eventCharitable,
    required this.eventFree,
    required this.eventPaid,
    required this.motorcycle,
    required this.car,
    required this.difficultyChip,
    required this.maintenanceUrgent,
    required this.maintenanceWarning,
    required this.maintenanceOk,
    required this.licensePlateTagBackground,
    required this.licensePlateTagText,
    required this.inputIcon,
    required this.primaryGradient,
    required this.overlayLight,
    required this.overlayMedium,
    required this.shadowLight,
    required this.shadowMedium,
  });

  /// Default Rideglory palette-backed extension.
  factory AppColorsExtension.rideglory() {
    return AppColorsExtension(
      success: AppColors.success,
      successLight: AppColors.successLight,
      warning: AppColors.warning,
      warningLight: AppColors.warningLight,
      info: AppColors.info,
      infoLight: AppColors.infoLight,
      error: AppColors.error,
      errorLight: AppColors.errorLight,
      eventOffRoad: AppColors.eventOffRoad,
      eventOnRoad: AppColors.eventOnRoad,
      eventExhibition: AppColors.eventExhibition,
      eventCharitable: AppColors.eventCharitable,
      eventFree: AppColors.eventFree,
      eventPaid: AppColors.eventPaid,
      motorcycle: AppColors.motorcycle,
      car: AppColors.car,
      difficultyChip: AppColors.difficultyChip,
      maintenanceUrgent: AppColors.maintenanceUrgent,
      maintenanceWarning: AppColors.maintenanceWarning,
      maintenanceOk: AppColors.maintenanceOk,
      licensePlateTagBackground: AppColors.licensePlateTagBackground,
      licensePlateTagText: AppColors.licensePlateTagText,
      inputIcon: AppColors.darkInputIcon,
      primaryGradient: AppColors.primaryGradient,
      overlayLight: AppColors.overlayLight,
      overlayMedium: AppColors.overlayMedium,
      shadowLight: AppColors.shadowLight,
      shadowMedium: AppColors.shadowMedium,
    );
  }

  @override
  AppColorsExtension copyWith({
    Color? success,
    Color? successLight,
    Color? warning,
    Color? warningLight,
    Color? info,
    Color? infoLight,
    Color? error,
    Color? errorLight,
    Color? eventOffRoad,
    Color? eventOnRoad,
    Color? eventExhibition,
    Color? eventCharitable,
    Color? eventFree,
    Color? eventPaid,
    Color? motorcycle,
    Color? car,
    Color? difficultyChip,
    Color? maintenanceUrgent,
    Color? maintenanceWarning,
    Color? maintenanceOk,
    Color? licensePlateTagBackground,
    Color? licensePlateTagText,
    Color? inputIcon,
    List<Color>? primaryGradient,
    Color? overlayLight,
    Color? overlayMedium,
    Color? shadowLight,
    Color? shadowMedium,
  }) {
    return AppColorsExtension(
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      info: info ?? this.info,
      infoLight: infoLight ?? this.infoLight,
      error: error ?? this.error,
      errorLight: errorLight ?? this.errorLight,
      eventOffRoad: eventOffRoad ?? this.eventOffRoad,
      eventOnRoad: eventOnRoad ?? this.eventOnRoad,
      eventExhibition: eventExhibition ?? this.eventExhibition,
      eventCharitable: eventCharitable ?? this.eventCharitable,
      eventFree: eventFree ?? this.eventFree,
      eventPaid: eventPaid ?? this.eventPaid,
      motorcycle: motorcycle ?? this.motorcycle,
      car: car ?? this.car,
      difficultyChip: difficultyChip ?? this.difficultyChip,
      maintenanceUrgent: maintenanceUrgent ?? this.maintenanceUrgent,
      maintenanceWarning: maintenanceWarning ?? this.maintenanceWarning,
      maintenanceOk: maintenanceOk ?? this.maintenanceOk,
      licensePlateTagBackground:
          licensePlateTagBackground ?? this.licensePlateTagBackground,
      licensePlateTagText: licensePlateTagText ?? this.licensePlateTagText,
      inputIcon: inputIcon ?? this.inputIcon,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      overlayLight: overlayLight ?? this.overlayLight,
      overlayMedium: overlayMedium ?? this.overlayMedium,
      shadowLight: shadowLight ?? this.shadowLight,
      shadowMedium: shadowMedium ?? this.shadowMedium,
    );
  }

  @override
  AppColorsExtension lerp(
    covariant AppColorsExtension? other,
    double t,
  ) {
    if (other == null) return this;

    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t)!;

    return AppColorsExtension(
      success: lerpColor(success, other.success),
      successLight: lerpColor(successLight, other.successLight),
      warning: lerpColor(warning, other.warning),
      warningLight: lerpColor(warningLight, other.warningLight),
      info: lerpColor(info, other.info),
      infoLight: lerpColor(infoLight, other.infoLight),
      error: lerpColor(error, other.error),
      errorLight: lerpColor(errorLight, other.errorLight),
      eventOffRoad: lerpColor(eventOffRoad, other.eventOffRoad),
      eventOnRoad: lerpColor(eventOnRoad, other.eventOnRoad),
      eventExhibition: lerpColor(eventExhibition, other.eventExhibition),
      eventCharitable: lerpColor(eventCharitable, other.eventCharitable),
      eventFree: lerpColor(eventFree, other.eventFree),
      eventPaid: lerpColor(eventPaid, other.eventPaid),
      motorcycle: lerpColor(motorcycle, other.motorcycle),
      car: lerpColor(car, other.car),
      difficultyChip: lerpColor(difficultyChip, other.difficultyChip),
      maintenanceUrgent: lerpColor(maintenanceUrgent, other.maintenanceUrgent),
      maintenanceWarning: lerpColor(
        maintenanceWarning,
        other.maintenanceWarning,
      ),
      maintenanceOk: lerpColor(maintenanceOk, other.maintenanceOk),
      licensePlateTagBackground: lerpColor(
        licensePlateTagBackground,
        other.licensePlateTagBackground,
      ),
      licensePlateTagText: lerpColor(
        licensePlateTagText,
        other.licensePlateTagText,
      ),
      inputIcon: lerpColor(inputIcon, other.inputIcon),
      primaryGradient: t < 0.5 ? primaryGradient : other.primaryGradient,
      overlayLight: lerpColor(overlayLight, other.overlayLight),
      overlayMedium: lerpColor(overlayMedium, other.overlayMedium),
      shadowLight: lerpColor(shadowLight, other.shadowLight),
      shadowMedium: lerpColor(shadowMedium, other.shadowMedium),
    );
  }
}


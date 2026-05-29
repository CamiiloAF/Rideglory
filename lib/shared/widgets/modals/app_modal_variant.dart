import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Semantic variants of [AppModal], mirroring the Pencil node `ibKDx`
/// ("Modal — Variantes"). Each variant drives the default icon, the icon
/// color, the icon circle fill + glow, the primary action button fill and the
/// primary action label color.
///
/// | Variant       | Icon                 | Icon color | Circle fill          | Primary fill | Primary label |
/// |---------------|----------------------|------------|----------------------|--------------|---------------|
/// | info          | info_outline_rounded | primary    | primarySubtle        | primary      | dark          |
/// | destructive   | delete_outline       | error      | error @ 10%          | error        | white         |
/// | warning       | warning_amber_rounded| warning    | warning @ 10%        | warning      | dark          |
/// | success       | check_circle         | statusGreen| statusGreen @ 10%    | statusGreen  | dark          |
enum AppModalVariant {
  info,
  destructive,
  warning,
  success;

  /// Default icon for the variant; callers may still override via
  /// `AppModal.icon`.
  IconData get icon => switch (this) {
    AppModalVariant.info => Icons.info_outline_rounded,
    AppModalVariant.destructive => Icons.delete_outline,
    AppModalVariant.warning => Icons.warning_amber_rounded,
    AppModalVariant.success => Icons.check_circle,
  };

  /// Accent color: icon tint and primary button fill.
  Color get accentColor => switch (this) {
    AppModalVariant.info => AppColors.primary,
    AppModalVariant.destructive => AppColors.error,
    AppModalVariant.warning => AppColors.warning,
    AppModalVariant.success => AppColors.statusGreen,
  };

  /// Background fill of the 60x60 icon circle.
  ///
  /// `info` uses the dedicated accent-subtle surface (`#2D2117`); the other
  /// variants use their accent color at ~10% opacity (the Pencil `1A` alpha).
  Color get circleFill => switch (this) {
    AppModalVariant.info => AppColors.primarySubtle,
    _ => accentColor.withValues(alpha: 0.10),
  };

  /// Soft glow color behind the icon circle.
  Color get glowColor => switch (this) {
    AppModalVariant.info => AppColors.primary.withValues(alpha: 0.19),
    AppModalVariant.destructive => AppColors.error.withValues(alpha: 0.19),
    AppModalVariant.warning => AppColors.warning.withValues(alpha: 0.15),
    AppModalVariant.success => AppColors.statusGreen.withValues(alpha: 0.15),
  };

  /// Blur radius of the icon circle glow (warning is slightly tighter).
  double get glowBlur => this == AppModalVariant.warning ? 20 : 24;

  /// Spread radius of the icon circle glow (warning has none).
  double get glowSpread => this == AppModalVariant.warning ? 0 : 4;

  /// Label color of the primary action button. Only `destructive` uses white;
  /// the other variants use the near-black `#0D0D0F` for legibility on their
  /// bright fills.
  Color get primaryLabelColor => this == AppModalVariant.destructive
      ? AppColors.textOnDarkPrimary
      : AppColors.darkBgPrimary;
}

import 'package:flutter/material.dart';

/// Centralized color palette for the Rideglory app
/// Theme: Orange (Stitch) — customColor: #f98c1f, colorMode: DARK
class AppColors {
  AppColors._();

  // ─── Primary / Brand ───────────────────────────────────────────────────────
  /// Main orange accent — Stitch customColor
  static const Color primary = Color(0xFFf98c1f);
  static const Color primaryDark = Color(0xFFe07510);
  static const Color primaryLight = Color(0xFFfbab56);

  // ─── Secondary ─────────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFFfbab56);
  static const Color secondaryDark = Color(0xFFf98c1f);
  static const Color secondaryLight = Color(0xFFfdc98c);

  // ─── Gradient ──────────────────────────────────────────────────────────────
  static List<Color> get primaryGradient => [primary, primaryLight];

  // ─── Dark-mode backgrounds (Stitch design) ─────────────────────────────────
  /// Page background — very dark brown/charcoal
  static const Color darkBackground = Color(0xFF111111);

  /// Card / surface elevation 1
  static const Color darkSurface = Color(0xFF1C1209);

  /// Elevated card / inputs
  static const Color darkSurfaceHighest = Color(0xFF261A0E);

  /// Borders on dark backgrounds
  static const Color darkBorder = Color(0xFF3D2810);

  /// Primary text on dark
  static const Color darkTextPrimary = Color(0xFFF1F5F9);

  /// Secondary text on dark
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  /// Leading/trailing icons in inputs (medium orange-brown)
  static const Color darkInputIcon = Color(0xFFD38F3A);

  // ─── Light-mode text/background (kept for compatibility) ───────────────────
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);

  static const Color backgroundGray = Color(0xFFF9FAFB);
  static const Color backgroundGrayLight = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color surfaceGray = Color(0xFFF3F4F6);

  // ─── Border colors ─────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderDark = Color(0xFFD1D5DB);

  // ─── Status ────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);

  // ─── Icons ─────────────────────────────────────────────────────────────────
  static const Color iconPrimary = primary;
  static const Color iconSecondary = darkTextSecondary;
  static const Color iconDisabled = textDisabled;

  // ─── Shadows ───────────────────────────────────────────────────────────────
  static Color get shadowLight => Colors.black.withValues(alpha: .05);
  static Color get shadowMedium => Colors.black.withValues(alpha: .1);
  static Color get shadowDark => Colors.black.withValues(alpha: .15);
  static Color primaryShadow({double opacity = 0.35}) =>
      primary.withValues(alpha: opacity);

  // ─── Overlays ──────────────────────────────────────────────────────────────
  static Color get overlayLight => Colors.white.withValues(alpha: 0.1);
  static Color get overlayMedium => Colors.white.withValues(alpha: 0.25);
  static Color get overlayStrong => Colors.white.withValues(alpha: 0.9);

  // ─── Domain-specific ───────────────────────────────────────────────────────
  static const Color motorcycle = primary;
  static const Color car = Color(0xFF3B82F6);

  static const Color eventOffRoad = Color(0xFF8B4513);
  static const Color eventOnRoad = primary;
  static const Color eventExhibition = Color(0xFF9333EA);
  static const Color eventCharitable = Color(0xFF14B8A6);

  static const Color difficultyChip = Color(0xFFEF4444);

  static const Color eventFree = Color(0xFF10B981);
  static const Color eventPaid = Color(0xFFD946EF);

  static const Color maintenanceUrgent = error;
  static const Color maintenanceWarning = warning;
  static const Color maintenanceOk = success;
}

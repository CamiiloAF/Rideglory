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

  // ─── Status (semantic — distinct from legacy success/warning/error) ──────────
  /// Status green — Tailwind green-500 (#22C55E); distinct from success (#10B981)
  static const Color statusGreen = Color(0xFF22C55E);
  /// Status warning — Tailwind yellow-500 (#EAB308); distinct from warning (#F59E0B)
  static const Color statusWarning = Color(0xFFEAB308);
  /// Status error — Tailwind red-500 (#EF4444); semantic alias for error token
  static const Color statusError = Color(0xFFEF4444);

  // ─── Icons ──────────────────────────────────────────────────────────────────
  static const Color iconPrimary = primary;
  static const Color iconSecondary = darkTextSecondary;
  static const Color iconDisabled = textDisabled;

  // ─── Shadows ────────────────────────────────────────────────────────────────
  static Color get shadowLight => Colors.black.withValues(alpha: .05);
  static Color get shadowMedium => Colors.black.withValues(alpha: .1);
  static Color get shadowDark => Colors.black.withValues(alpha: .15);
  static Color primaryShadow({double opacity = 0.35}) =>
      primary.withValues(alpha: opacity);

  // ─── Overlays ───────────────────────────────────────────────────────────────
  static Color get overlayLight => Colors.white.withValues(alpha: 0.1);
  static Color get overlayMedium => Colors.white.withValues(alpha: 0.25);
  static Color get overlayStrong => Colors.white.withValues(alpha: 0.9);

  // ─── Domain-specific ───────────────────────────────────────────────────────
  static const Color motorcycle = primary;
  static const Color car = Color(0xFF3B82F6);

  static const Color eventTourism = Color(0xFF9333EA);
  static const Color eventUrban = primary;
  static const Color eventOffRoad = Color(0xFF8B4513);
  static const Color eventCompetition = Color(0xFFEF4444);
  static const Color eventSolidarity = Color(0xFF14B8A6);
  static const Color eventShortDistance = Color(0xFF8B5CF6);

  static const Color difficultyChip = Color(0xFFEF4444);

  static const Color eventFree = Color(0xFF10B981);
  static const Color eventPaid = Color(0xFFD946EF);

  static const Color maintenanceUrgent = error;
  static const Color maintenanceWarning = warning;
  static const Color maintenanceOk = success;

  /// Yellow background for license plate tag (detail/forms)
  static const Color licensePlateTagBackground = Color(0xFFFBBF24);
  /// Dark text on license plate tag
  static const Color licensePlateTagText = Color(0xFF1F2937);

  // ─── Pencil design system tokens ──────────────────────────────────────────
  /// Pencil $bg-primary — page background
  static const Color darkBgPrimary = Color(0xFF0D0D0F);
  /// Pencil $bg-secondary — field / secondary surface
  static const Color darkBgSecondary = Color(0xFF1A1A1F);
  /// Pencil $bg-card — card surface
  static const Color darkCard = Color(0xFF1E1E24);
  /// Pencil $bg-tertiary
  static const Color darkTertiary = Color(0xFF242429);
  /// Pencil $border
  static const Color darkBorderPrimary = Color(0xFF2A2A32);
  /// Pencil $border-light
  static const Color darkBorderLight = Color(0xFF3A3A44);
  /// Pencil $text-primary (on dark)
  static const Color textOnDarkPrimary = Color(0xFFFFFFFF);
  /// Pencil $text-secondary
  static const Color textOnDarkSecondary = Color(0xFF9CA3AF);
  /// Pencil $text-tertiary
  static const Color textOnDarkTertiary = Color(0xFF6B7280);
  /// Pencil $accent-subtle
  static const Color primarySubtle = Color(0xFF2D2117);
  /// Pencil $tab-bar-bg
  static const Color tabBarBackground = Color(0xFF15151A);
  /// Pencil $tab-inactive
  static const Color tabInactive = Color(0xFF6B7280);
  /// Pencil success-subtle — Vigente badge bg, Realizado badge bg
  static const Color successSubtle = Color(0xFF162A1F);
  /// Pencil warning-subtle — Por vencer badge bg
  static const Color warningSubtle = Color(0xFF2A2200);
  /// Pencil error-subtle — Vencido badge bg
  static const Color errorSubtle = Color(0xFF2D1010);
  /// Pencil info-subtle — SOAT icon bg
  static const Color infoSubtle = Color(0xFF1B2E4A);
  /// Tracking rider card background
  static const Color riderCardBg = Color(0xFF161616);
  /// Tracking map dark background
  static const Color trackingMapBg = Color(0xFF0C1018);
}

